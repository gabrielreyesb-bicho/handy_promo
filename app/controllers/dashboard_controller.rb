class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  
  def index
    # Parámetro de mes - formato simple: "YYYY-MM"
    if params[:month].present?
      # Parsear directamente YYYY-MM
      @selected_month = Date.parse("#{params[:month]}-01")
    else
      # Por defecto: mes actual
      @selected_month = Date.today.beginning_of_month
    end
    
    @selected_year = @selected_month.year
    @selected_month_num = @selected_month.month
    @selected_month_str = @selected_month.strftime("%Y-%m")
    @months_to_show = params[:months]&.to_i || 6 # Por defecto últimos 6 meses
    
    # Calcular rango de fechas para análisis
    @start_date = @selected_month - (@months_to_show - 1).months
    @end_date = @selected_month.end_of_month
    
    # === CALCULAR PRESUPUESTO MENSUAL Y DINERO DISPONIBLE ===
    calculate_budget_summary
    
    # === CALCULAR CATEGORÍAS QUE EXCEDIERON PRESUPUESTO ===
    calculate_exceeded_budgets
    
    # === SECCIÓN 1: RESUMEN FINANCIERO DEL MES ===
    calculate_monthly_summary
    
    # === SECCIÓN 2: ANÁLISIS DE INGRESOS VS EGRESOS ===
    calculate_income_vs_expenses
    
    # === SECCIÓN 3: ANÁLISIS DE GASTOS POR CATEGORÍA ===
    calculate_category_analysis
    
    # === SECCIÓN 4: GRÁFICA HISTÓRICA DE GASTOS POR CATEGORÍA ===
    calculate_category_historical_chart
    
    # === SECCIÓN 5: TENDENCIAS DE GASTOS POR CATEGORÍA ===
    calculate_category_trends
    
    # === SECCIÓN 5: ANÁLISIS DE TARJETAS ===
    calculate_card_analysis
    
    # === SECCIÓN 6: ESTADOS DE CUENTA ===
    calculate_statements_summary
    
    # === SECCIÓN 7: DEUDAS Y OBLIGACIONES ===
    calculate_debts_and_obligations
    
    # === SECCIÓN 8: INVERSIONES Y PATRIMONIO ===
    calculate_investments_and_assets
    
    # === SECCIÓN 8.5: HISTÓRICO DE PATRIMONIO NETO ===
    calculate_net_worth_historical
    
    # === SECCIÓN 9: MÉTRICAS PRINCIPALES ===
    calculate_main_metrics
    
    # Contar transacciones sin clasificar del mes seleccionado
    month_transactions = Transaction.where(user: current_user).by_month(@selected_year, @selected_month_num)
    @unclassified_count = month_transactions.unclassified.count
  end

  private

  # Calcular presupuesto mensual total
  def calculate_budget_summary
    # Obtener todos los presupuestos de egreso del mes seleccionado
    month_budgets = Budget.for_user(current_user)
                         .for_month(@selected_year, @selected_month_num)
                         .joins(:category)
                         .where(categories: { transaction_type: 'egreso' })
    
    # Sumar todos los presupuestos de egreso
    @monthly_budget = month_budgets.sum(:amount) || 0
  end

  # Calcular categorías que excedieron su presupuesto
  def calculate_exceeded_budgets
    # Obtener todos los presupuestos de egreso del mes seleccionado
    month_budgets = Budget.for_user(current_user)
                         .for_month(@selected_year, @selected_month_num)
                         .joins(:category)
                         .where(categories: { transaction_type: 'egreso' })
                         .includes(:category)
    
    exceeded_categories = []
    
    month_budgets.each do |budget|
      budgeted_amount = budget.budgeted_amount
      actual_expense = budget.actual_expense
      
      # Solo incluir si excedió el presupuesto
      if actual_expense > budgeted_amount && budgeted_amount > 0
        excess_amount = actual_expense - budgeted_amount
        excess_percentage = (excess_amount / budgeted_amount * 100).round(1)
        
        exceeded_categories << {
          category_name: budget.category.name,
          budgeted: budgeted_amount,
          actual: actual_expense,
          excess: excess_amount,
          excess_percentage: excess_percentage
        }
      end
    end
    
    # Ordenar por mayor porcentaje excedido y tomar top 5
    @exceeded_budgets = exceeded_categories.sort_by { |cat| -cat[:excess_percentage] }.first(5) || []
  end

  # Método helper para calcular ingresos de un rango de fechas
  # Usa la misma lógica en calculate_monthly_summary y calculate_income_vs_expenses
  # EXCLUYE pagos de tarjeta de crédito que no son ingresos reales
  # Devuelve un hash con :amount y :count para garantizar consistencia
  def calculate_income_for_period(month_start, month_end)
    month_transactions = Transaction.where(user: current_user, date: month_start..month_end)
    debit_cards = Card.where(user: current_user, card_type: 'debito').pluck(:id)
    
    Rails.logger.info "🔍 [INCOME DEBUG] Rango: #{month_start} a #{month_end}"
    Rails.logger.info "🔍 [INCOME DEBUG] Tarjetas débito: #{debit_cards.inspect}"
    Rails.logger.info "🔍 [INCOME DEBUG] Total abonos: #{month_transactions.abonos.count}"
    
    # Patrones para identificar pagos de tarjeta (NO son ingresos)
    payment_patterns = [
      "%PAGO TARJETA%",
      "%PAGO TDC%",
      "%BMOVIL.PAGO%",
      "%PAGO TARJETA DE CREDITO%",
      "%PAGO TARJETA DE CRÉDITO%",
      "%PAGO TARJETA DE CREDITO/%",
      "%PAGO TARJETA DE CRÉDITO/%"
    ]
    
    # Abonos en tarjetas de débito (excluyendo pagos de tarjeta)
    abonos_debito = month_transactions.abonos.where(card_id: debit_cards)
    # Excluir pagos de tarjeta de crédito desde débito
    abonos_debito = abonos_debito.where.not(
      payment_patterns.map { |pattern| "UPPER(description) LIKE ?" }.join(" OR "),
      *payment_patterns
    )
    income_from_debit = abonos_debito.sum(:amount) || 0
    count_from_debit = abonos_debito.count
    
    Rails.logger.info "🔍 [INCOME DEBUG] Abonos en débito (sin pagos tarjeta): #{count_from_debit}, Suma: #{income_from_debit}"
    
    # Abonos que son claramente ingresos aunque estén en tarjetas de crédito
    # (esto corrige errores de clasificación del parser)
    # EXCLUIR pagos de tarjeta de crédito
    abonos_credito_ingresos = month_transactions.abonos
                                                  .where.not(card_id: debit_cards)
                                                  .where("UPPER(description) LIKE ? OR UPPER(description) LIKE ? OR UPPER(description) LIKE ? OR UPPER(description) LIKE ? OR UPPER(description) LIKE ?",
                                                         "%DEPOSITO DE TERCERO%", "%SPEI RECIBIDO%", "%PAGO DE NOMINA%", "%TRANSFERENCIA RECIBIDA%", "%ABONO A TU CUENTA%")
                                                  .where.not(
                                                    payment_patterns.map { |pattern| "UPPER(description) LIKE ?" }.join(" OR "),
                                                    *payment_patterns
                                                  )
    income_from_misclassified = abonos_credito_ingresos.sum(:amount) || 0
    count_from_misclassified = abonos_credito_ingresos.count
    
    Rails.logger.info "🔍 [INCOME DEBUG] Ingresos mal clasificados (sin pagos tarjeta): #{count_from_misclassified}, Suma: #{income_from_misclassified}"
    total_amount = income_from_debit + income_from_misclassified
    total_count = count_from_debit + count_from_misclassified
    Rails.logger.info "🔍 [INCOME DEBUG] Total ingresos (sin pagos tarjeta): #{total_count} transacciones, $#{total_amount}"
    
    { amount: total_amount, count: total_count }
  end

  def calculate_monthly_summary
    # Transacciones del mes seleccionado - usar la misma lógica que calculate_income_vs_expenses
    month_start = Date.new(@selected_year, @selected_month_num, 1)
    month_end = month_start.end_of_month
    month_transactions = Transaction.where(user: current_user, date: month_start..month_end)
    
    # DEBUG: Log para verificar qué está pasando
    Rails.logger.info "🔍 [DASHBOARD DEBUG] Mes seleccionado: #{@selected_year}-#{@selected_month_num}"
    Rails.logger.info "🔍 [DASHBOARD DEBUG] Rango: #{month_start} a #{month_end}"
    Rails.logger.info "🔍 [DASHBOARD DEBUG] Transacciones encontradas: #{month_transactions.count}"
    
    # Ingresos (abonos) - Usar la lógica correcta que excluye pagos de tarjeta
    # Solo contar abonos en tarjetas de débito o ingresos reales mal clasificados
    income_data = calculate_income_for_period(month_start, month_end)
    @month_income = income_data[:amount]
    @income_count = income_data[:count]
    Rails.logger.info "🔍 [DASHBOARD DEBUG] Ingresos calculados (con filtros): #{@income_count} transacciones, $#{@month_income}"
    
    # Egresos (cargos) - ALINEAR CON VISTA DE TRANSACCIONES: 
    # Cargos clasificados sin transferencias + cargos sin clasificar
    # #region agent log
    begin
      all_cargos = month_transactions.cargos
      Rails.logger.info "🔍 [EXPENSES DEBUG] Total cargos en mes: #{all_cargos.count}"
      Rails.logger.info "🔍 [EXPENSES DEBUG] Suma de todos los cargos (sin filtrar): #{all_cargos.sum(:amount) || 0}"
      
      # Separar cargos clasificados y sin clasificar (igual que en transactions_controller)
      cargos_clasificados = all_cargos.where.not(provider_id: nil)
      cargos_sin_clasificar = all_cargos.where(provider_id: nil)
      
      # Cargos clasificados: excluir transferencias
      total_clasificados = 0
      if cargos_clasificados.exists?
        cargos_clasificados = cargos_clasificados.joins(:provider) unless cargos_clasificados.joins_values.any? { |j| j.respond_to?(:name) && j.name == :provider }
        total_clasificados = cargos_clasificados.excluding_transfers.sum(:amount) || 0
      end
      
      # Cargos sin clasificar: sumar todos (no podemos saber si son transferencias)
      total_sin_clasificar = cargos_sin_clasificar.sum(:amount) || 0
      
      Rails.logger.info "🔍 [EXPENSES DEBUG] Cargos clasificados (sin transferencias): #{cargos_clasificados.excluding_transfers.count}, Total: #{total_clasificados}"
      Rails.logger.info "🔍 [EXPENSES DEBUG] Cargos sin clasificar: #{cargos_sin_clasificar.count}, Total: #{total_sin_clasificar}"
      
      @month_expenses = total_clasificados + total_sin_clasificar
      Rails.logger.info "🔍 [EXPENSES DEBUG] Total egresos calculado: #{@month_expenses}"
    rescue => e
      Rails.logger.error "🔍 [EXPENSES DEBUG] Error al calcular egresos: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Fallback: calcular sin joins si hay error
      @month_expenses = month_transactions.cargos.sum(:amount) || 0
    end
    # #endregion
    
    # Calcular dinero disponible: Presupuesto mensual - Gastos ejecutados
    @available_money = @monthly_budget - @month_expenses
    
    # Balance neto
    @month_balance = @month_income - @month_expenses
    
    # Contar transacciones de gastos e ingresos
    # Para gastos: usar la misma lógica que el cálculo de @month_expenses
    begin
      cargos_clasificados = month_transactions.cargos.where.not(provider_id: nil)
      cargos_sin_clasificar = month_transactions.cargos.where(provider_id: nil)
      cargos_clasificados = cargos_clasificados.joins(:provider) unless cargos_clasificados.joins_values.any? { |j| j.respond_to?(:name) && j.name == :provider }
      @expenses_count = cargos_clasificados.excluding_transfers.count + cargos_sin_clasificar.count
    rescue
      @expenses_count = month_transactions.cargos.count
    end
    
    # Para ingresos: el conteo ya se calculó junto con el monto en calculate_income_for_period
    # para garantizar que ambos usen exactamente la misma lógica
    
    # Comparación con mes anterior
    prev_month = @selected_month - 1.month
    prev_month_start = prev_month.beginning_of_month
    prev_month_end = prev_month.end_of_month
    
    # Calcular mes anterior con la misma lógica que el mes actual
    prev_month_transactions = Transaction.where(user: current_user, date: prev_month_start..prev_month_end)
    prev_month_income = prev_month_transactions.abonos.sum(:amount) || 0
    begin
      prev_all_cargos = prev_month_transactions.cargos
      prev_cargos_clasificados = prev_all_cargos.where.not(provider_id: nil)
      prev_cargos_sin_clasificar = prev_all_cargos.where(provider_id: nil)
      
      prev_total_clasificados = 0
      if prev_cargos_clasificados.exists?
        prev_cargos_clasificados = prev_cargos_clasificados.joins(:provider) unless prev_cargos_clasificados.joins_values.any? { |j| j.respond_to?(:name) && j.name == :provider }
        prev_total_clasificados = prev_cargos_clasificados.excluding_transfers.sum(:amount) || 0
      end
      
      prev_total_sin_clasificar = prev_cargos_sin_clasificar.sum(:amount) || 0
      prev_month_expenses = prev_total_clasificados + prev_total_sin_clasificar
    rescue => e
      Rails.logger.error "🔍 [EXPENSES DEBUG] Error al calcular egresos del mes anterior: #{e.message}"
      prev_month_expenses = prev_month_transactions.cargos.sum(:amount) || 0
    end
    
    @income_change = prev_month_income > 0 ? ((@month_income - prev_month_income) / prev_month_income * 100).round(1) : 0
    @expenses_change = prev_month_expenses > 0 ? ((@month_expenses - prev_month_expenses) / prev_month_expenses * 100).round(1) : 0
    @balance_change = prev_month_income - prev_month_expenses != 0 ? 
                      ((@month_balance - (prev_month_income - prev_month_expenses)) / (prev_month_income - prev_month_expenses).abs * 100).round(1) : 0
    
    # Totales de transacciones
    @month_transactions_count = month_transactions.count
    @month_cargos_count = month_transactions.cargos.count
    @month_abonos_count = month_transactions.abonos.count
  end

  def calculate_income_vs_expenses
    # Datos para últimos N meses
    @income_expenses_data = {}
    @income_data = {}
    @expenses_data = {}
    
    (@months_to_show - 1).downto(0) do |i|
      month_date = @selected_month - i.months
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month
      
      month_transactions = Transaction.where(user: current_user, date: month_start..month_end)
      
      # Definir month_label antes de usarlo
      month_label = month_date.strftime("%b %Y")
      
      # Usar la misma lógica que calculate_monthly_summary para garantizar consistencia
      # Excluir pagos de tarjeta de crédito
      income_data = calculate_income_for_period(month_start, month_end)
      income = income_data[:amount]
      # #region agent log
      begin
        all_month_cargos = month_transactions.cargos
        month_cargos_clasificados = all_month_cargos.where.not(provider_id: nil)
        month_cargos_sin_clasificar = all_month_cargos.where(provider_id: nil)
        
        total_clasificados = 0
        if month_cargos_clasificados.exists?
          month_cargos_clasificados = month_cargos_clasificados.joins(:provider) unless month_cargos_clasificados.joins_values.any? { |j| j.respond_to?(:name) && j.name == :provider }
          total_clasificados = month_cargos_clasificados.excluding_transfers.sum(:amount) || 0
        end
        
        total_sin_clasificar = month_cargos_sin_clasificar.sum(:amount) || 0
        expenses = total_clasificados + total_sin_clasificar
        
        if month_date == @selected_month
          Rails.logger.info "🔍 [EXPENSES DEBUG] Mes #{month_label}: #{all_month_cargos.count} cargos totales, Clasificados: #{month_cargos_clasificados.excluding_transfers.count}, Sin clasificar: #{month_cargos_sin_clasificar.count}, Total: #{expenses}"
        end
      rescue => e
        Rails.logger.error "🔍 [EXPENSES DEBUG] Error en calculate_income_vs_expenses para #{month_label}: #{e.message}"
        expenses = month_transactions.cargos.sum(:amount) || 0
      end
      # #endregion
      balance = income - expenses
      @income_expenses_data[month_label] = {
        income: income,
        expenses: expenses,
        balance: balance
      }
      @income_data[month_label] = income
      @expenses_data[month_label] = expenses
    end
    
    # Promedios últimos 3 meses
    last_3_months = @income_expenses_data.values.last(3)
    @avg_income_3m = last_3_months.any? ? (last_3_months.sum { |d| d[:income] } / last_3_months.size.to_f) : 0
    @avg_expenses_3m = last_3_months.any? ? (last_3_months.sum { |d| d[:expenses] } / last_3_months.size.to_f) : 0
    
    # Tendencias (comparar mes actual con mes anterior)
    # Si hay al menos 2 meses de datos, comparar el último con el anterior
    if @income_expenses_data.size >= 2
      current_month = @income_expenses_data.values.last
      previous_month = @income_expenses_data.values[-2]
      
      # Tendencias de ingresos
      if previous_month[:income] > 0
        @income_trend = ((current_month[:income] - previous_month[:income]) / previous_month[:income] * 100).round(1)
      elsif current_month[:income] > 0 && previous_month[:income] == 0
        @income_trend = 100.0 # Si no había ingresos antes y ahora sí, es un aumento del 100%
      else
        @income_trend = 0
      end
      
      # Tendencias de egresos
      if previous_month[:expenses] > 0
        @expenses_trend = ((current_month[:expenses] - previous_month[:expenses]) / previous_month[:expenses] * 100).round(1)
      elsif current_month[:expenses] > 0 && previous_month[:expenses] == 0
        @expenses_trend = 100.0 # Si no había egresos antes y ahora sí, es un aumento del 100%
      else
        @expenses_trend = 0
      end
    else
      @income_trend = 0
      @expenses_trend = 0
    end
  end

  def calculate_category_analysis
    # Gastos por categoría del mes actual (excluyendo transferencias)
    # Filtrar por categoría del proveedor (nuevo diseño)
    month_transactions = Transaction.where(user: current_user)
                                    .joins(:provider)
                                    .by_month(@selected_year, @selected_month_num)
                                    .cargos
                                    .excluding_transfers
    
    category_totals = month_transactions.group('providers.category_id')
                                        .sum(:amount)
    
    # Agrupar por categoría principal
    @category_data = {}
    @category_parent_totals = {}
    @category_name_to_id = {} # Mapeo de nombre de categoría a ID para navegación
    
    category_totals.each do |category_id, amount|
      category = Category.where(user: current_user).find(category_id)
      parent = category.parent
      
      if parent
        parent_name = parent.name
        @category_parent_totals[parent_name] ||= 0
        @category_parent_totals[parent_name] += amount
        @category_data[parent_name] ||= []
        @category_data[parent_name] << { name: category.name, amount: amount }
        # Guardar el ID de la categoría principal para navegación
        @category_name_to_id[parent_name] = parent.id unless @category_name_to_id[parent_name]
      else
        @category_data[category.name] ||= []
        @category_data[category.name] << { name: category.name, amount: amount }
        @category_parent_totals[category.name] ||= 0
        @category_parent_totals[category.name] += amount
        # Guardar el ID de la categoría para navegación
        @category_name_to_id[category.name] = category.id unless @category_name_to_id[category.name]
      end
    end
    
    # Ordenar por monto
    @category_parent_totals = @category_parent_totals.sort_by { |k, v| -v }.to_h
    
    # Calcular total de gastos clasificados (solo para porcentajes)
    @total_classified_expenses = @category_parent_totals.values.sum
    
    # Top 5 categorías
    @top_categories = @category_parent_totals.first(5).to_h
    
    # Comparación con mes anterior (excluyendo transferencias)
    prev_month = @selected_month - 1.month
    prev_month_transactions = Transaction.where(user: current_user)
                                        .joins(:provider)
                                        .by_month(prev_month.year, prev_month.month)
                                        .cargos
                                        .excluding_transfers
    
    prev_category_totals = prev_month_transactions.group('providers.category_id')
                                                  .sum(:amount)
    
    @category_comparison = {}
    @category_parent_totals.each do |cat_name, amount|
      # Buscar el total del mes anterior para esta categoría
      prev_amount = 0
      # Buscar categorías principales con este nombre
      parent_categories = Category.where(user: current_user, name: cat_name, parent_id: nil)
      parent_categories.each do |parent_cat|
        prev_amount += prev_category_totals[parent_cat.id] || 0
        # Sumar también las subcategorías
        parent_cat.children.each do |child|
          prev_amount += prev_category_totals[child.id] || 0
        end
      end
      
      # Si no encontró como padre, buscar como hijo
      if prev_amount == 0
        child_categories = Category.where(user: current_user, name: cat_name).where.not(parent_id: nil)
        child_categories.each do |child_cat|
          # Si es hijo, sumar el total del padre en el mes anterior
          if child_cat.parent
            parent_id = child_cat.parent.id
            prev_amount += prev_category_totals[parent_id] || 0
            # También sumar todas las subcategorías del padre
            child_cat.parent.children.each do |sibling|
              prev_amount += prev_category_totals[sibling.id] || 0
            end
          end
        end
      end
      
      change = prev_amount > 0 ? ((amount - prev_amount) / prev_amount * 100).round(1) : (amount > 0 ? 100 : 0)
      @category_comparison[cat_name] = {
        previous: prev_amount,
        change: change
      }
    end
  end

  # Calcular datos históricos para gráfica de líneas (top 5 categorías, últimos 6 meses)
  def calculate_category_historical_chart
    # Obtener top 5 categorías del mes actual
    top_5_categories = @category_parent_totals.first(5).to_h.keys
    
    @category_historical_data = {}
    
    # Para cada categoría top, calcular gastos en los últimos 6 meses (5 anteriores + actual)
    5.downto(0) do |i|
      month_date = @selected_month - i.months
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month
      month_label = month_date.strftime("%b %Y")
      
      top_5_categories.each do |cat_name|
        # Buscar categorías principales con este nombre
        parent_categories = Category.where(user: current_user, name: cat_name, parent_id: nil)
        category_ids = parent_categories.pluck(:id)
        # Agregar todas las subcategorías
        parent_categories.each do |parent_cat|
          category_ids += parent_cat.children.pluck(:id)
        end
        
        # Si no encontró como padre, buscar como hijo
        if category_ids.empty?
          child_categories = Category.where(user: current_user, name: cat_name).where.not(parent_id: nil)
          child_categories.each do |child_cat|
            if child_cat.parent
              category_ids << child_cat.parent.id
              category_ids += child_cat.parent.children.pluck(:id)
            end
          end
        end
        
        category_ids.uniq!
        
        # Calcular gastos de esta categoría en este mes
        total = Transaction.where(user: current_user)
                          .joins(:provider)
                          .where(date: month_start..month_end)
                          .cargos
                          .excluding_transfers
                          .where(providers: { category_id: category_ids })
                          .sum(:amount) || 0
        
        @category_historical_data[cat_name] ||= {}
        @category_historical_data[cat_name][month_label] = total
      end
    end
  end

  def calculate_category_trends
    # Datos de tendencias por categoría (últimos N meses)
    @category_trends = {}
    # Mostrar TODAS las categorías con transacciones, no solo las top 5
    all_categories = @category_parent_totals.keys
    
    all_categories.each do |cat_name|
      # Buscar categorías principales con este nombre
      parent_categories = Category.where(user: current_user, name: cat_name, parent_id: nil)
      category_ids = parent_categories.pluck(:id)
      # Agregar todas las subcategorías
      parent_categories.each do |parent_cat|
        category_ids += parent_cat.children.pluck(:id)
      end
      
      # Si no encontró como padre, buscar como hijo
      if category_ids.empty?
        child_categories = Category.where(user: current_user, name: cat_name).where.not(parent_id: nil)
        child_categories.each do |child_cat|
          if child_cat.parent
            # Incluir el padre y todas sus subcategorías
            category_ids << child_cat.parent.id
            category_ids += child_cat.parent.children.pluck(:id)
          end
        end
      end
      
      category_ids.uniq!
      
      trend_data = {}
      (@months_to_show - 1).downto(0) do |i|
        month_date = @selected_month - i.months
        month_start = month_date.beginning_of_month
        month_end = month_date.end_of_month
        
        total = Transaction.where(user: current_user)
                          .joins(:provider)
                          .where(date: month_start..month_end)
                          .cargos
                          .excluding_transfers
                          .where(providers: { category_id: category_ids })
                          .sum(:amount) || 0
        
        month_label = month_date.strftime("%b %Y")
        trend_data[month_label] = total
      end
      
      @category_trends[cat_name] = trend_data
    end
  end

  def calculate_card_analysis
    # Gastos por tarjeta del mes actual
    month_transactions = Transaction.where(user: current_user).by_month(@selected_year, @selected_month_num)
    
    @card_expenses = month_transactions.joins(:provider)
                                      .cargos
                                      .excluding_transfers
                                      .group(:card_id)
                                      .sum(:amount)
                                      .transform_keys { |id| Card.where(user: current_user).find(id).name }
    
    @card_income = month_transactions.abonos
                                     .group(:card_id)
                                     .sum(:amount)
                                     .transform_keys { |id| Card.where(user: current_user).find(id).name }
    
    # Estados de cuenta recientes
    @recent_statements = Statement.where(user: current_user)
                                  .includes(:cards, :card)
                                  .order(cutoff_date: :desc)
                                  .limit(5)
  end

  def calculate_statements_summary
    # Estados de cuenta con discrepancias
    @statements_with_issues = Statement.where(user: current_user)
                                       .includes(:cards, :card)
                                       .order(cutoff_date: :desc)
                                       .limit(10)
                                       .select { |s| !s.balanced? || !s.minimum_payment_balanced? }
    
    # Gastos no deseados (comisiones e intereses del mes)
    month_transactions = Transaction.where(user: current_user).by_month(@selected_year, @selected_month_num)
    @unwanted_expenses = month_transactions.joins(:provider)
                                          .cargos
                                          .excluding_transfers
                                          .where("LOWER(description) LIKE ? OR LOWER(description) LIKE ?", 
                                                 "%comision%", "%interes%")
                                          .sum(:amount) || 0
  end
  
  def calculate_debts_and_obligations
    # Obtener todos los planes de pagos activos
    active_plans = InstallmentPurchase.where(user: current_user).active_only.includes(:card, :installment_payments)
    
    # Total de adeudo
    @total_debt = active_plans.sum { |p| p.remaining_amount } || 0
    
    # Pago mensual total comprometido
    @total_monthly_payment = active_plans.sum { |p| p.monthly_payment } || 0
    
    # Total pagado vs total con intereses (para progreso)
    @total_paid_amount = active_plans.sum { |p| p.paid_amount } || 0
    @total_with_interest = active_plans.sum { |p| p.total_with_interest } || 0
    @debt_progress_percentage = @total_with_interest > 0 ? ((@total_paid_amount / @total_with_interest) * 100).round(1) : 0
    
    # Desglose por plazo
    @short_term_debt = 0 # ≤12 meses
    @long_term_debt = 0 # >12 meses
    
    active_plans.each do |plan|
      remaining = plan.remaining_amount
      if plan.remaining_months <= 12
        @short_term_debt += remaining
      else
        @long_term_debt += remaining
      end
    end
    
    # Top 5 planes activos ordenados por monto restante (mayor primero)
    @top_plans = active_plans.sort_by { |p| -p.remaining_amount }.first(5) || []
    
    # Planes con pagos vencidos
    @overdue_plans = active_plans.select { |p| p.is_overdue? } || []
    
    # Planes próximos a vencer (próximos 7 días)
    seven_days_from_now = Date.today + 7.days
    @upcoming_plans = active_plans.select do |p|
      next_payment = p.next_payment_date
      next_payment && next_payment <= seven_days_from_now && next_payment >= Date.today
    end || []
  end
  
  def calculate_investments_and_assets
    # === INVERSIONES ===
    # Obtener todas las inversiones activas
    active_investments = Investment.where(user: current_user).active_only.includes(:card, :provider)
    
    # Balance total actual
    @total_investment_balance = active_investments.sum { |inv| inv.current_balance } || 0
    
    # Total aportado
    @total_contributions = active_investments.sum { |inv| inv.total_contributions } || 0
    
    # Total planeado (solo inversiones con meta)
    exchange_rate = current_user.usd_to_mxn_exchange_rate || 17.0
    committed_goal_investments = active_investments.where(investment_type: ['committed', 'goal'])
    @total_planned = committed_goal_investments.sum do |inv|
      if inv.currency == 'USD'
        (inv.target_amount || 0) * exchange_rate
      else
        inv.target_amount || 0
      end
    end || 0
    
    # Rendimiento total
    @total_returns = active_investments.sum { |inv| inv.total_returns } || 0
    @total_return_percentage = @total_contributions > 0 ? ((@total_returns / @total_contributions) * 100).round(2) : 0
    
    # Progreso hacia objetivos (solo inversiones con meta)
    @investment_progress_percentage = @total_planned > 0 ? ((@total_contributions / @total_planned) * 100).round(1) : 0
    
    # Top 5 inversiones ordenadas por balance actual (mayor primero)
    @top_investments = active_investments.sort_by { |inv| -inv.current_balance }.first(5) || []
    
    # Distribución por tipo
    @investments_by_type = {
      flexible: active_investments.where(investment_type: 'flexible').sum { |inv| inv.current_balance } || 0,
      committed: active_investments.where(investment_type: 'committed').sum { |inv| inv.current_balance } || 0,
      goal: active_investments.where(investment_type: 'goal').sum { |inv| inv.current_balance } || 0
    }
    
    # === ACTIVOS (Propiedades, Equity Empresarial, etc.) ===
    active_assets = Asset.where(user: current_user).active_only.includes(:installment_purchase)
    
    # Valor total de activos (para business_equity usar ownership_value)
    @total_assets_value = active_assets.sum { |asset| asset.asset_type == 'business_equity' ? asset.ownership_value : asset.current_value } || 0
    
    # Equity real (valor menos deudas vinculadas)
    @total_assets_equity = active_assets.sum { |asset| asset.equity } || 0
    
    # Distribución por tipo de activo
    @assets_by_type = {
      property: active_assets.properties.sum(:current_value) || 0,
      business_equity: active_assets.business_equity.sum { |asset| asset.ownership_value } || 0,
      vehicle: active_assets.vehicles.sum(:current_value) || 0,
      other: active_assets.where(asset_type: 'other').sum(:current_value) || 0
    }
    
    # Total de activos (inversiones + otros activos)
    @total_assets = @total_investment_balance + @total_assets_equity
  end

  # Calcular histórico de patrimonio neto (últimos 6 meses)
  def calculate_net_worth_historical
    @net_worth_historical = {}
    
    # Calcular patrimonio neto para los últimos 6 meses (5 anteriores + actual)
    5.downto(0) do |i|
      month_date = @selected_month - i.months
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month
      month_label = month_date.strftime("%b %Y")
      
      # Calcular inversiones del mes
      active_investments = Investment.where(user: current_user)
                                    .active_only
                                    .where('created_at <= ?', month_end)
      
      investment_balance = active_investments.sum do |inv|
        contributions = inv.investment_movements
                          .where('date <= ?', month_end)
                          .where(movement_type: 'contribution')
                          .sum(:amount) || 0
        withdrawals = inv.investment_movements
                        .where('date <= ?', month_end)
                        .where(movement_type: 'withdrawal')
                        .sum(:amount) || 0
        contributions - withdrawals
      end || 0
      
      # Calcular activos del mes
      active_assets = Asset.where(user: current_user)
                          .active_only
                          .where('created_at <= ?', month_end)
      
      assets_equity = active_assets.sum do |asset|
        # Calcular equity considerando pagos realizados hasta ese mes
        if asset.installment_purchase
          total_paid = asset.installment_purchase.installment_payments
                           .where('paid_date <= ?', month_end)
                           .regular_payments
                           .where.not(paid_amount: nil)
                           .sum(:paid_amount) || 0
          asset.current_value - (asset.installment_purchase.total_with_interest - total_paid)
        else
          asset.current_value
        end
      end || 0
      
      total_assets = investment_balance + assets_equity
      
      # Calcular deuda del mes
      active_plans = InstallmentPurchase.where(user: current_user)
                                       .active_only
                                       .where('created_at <= ?', month_end)
      
      total_debt = active_plans.sum do |plan|
        total = plan.total_with_interest
        paid = plan.installment_payments
                   .where('paid_date <= ?', month_end)
                   .regular_payments
                   .where.not(paid_amount: nil)
                   .sum(:paid_amount) || 0
        total - paid
      end || 0
      
      # Patrimonio neto = Activos - Deudas
      net_worth = total_assets - total_debt
      
      @net_worth_historical[month_label] = net_worth
    end
  end
  
  def calculate_main_metrics
    # Asegurar que las variables estén inicializadas
    @total_debt ||= 0
    @total_investment_balance ||= 0
    @total_assets ||= 0
    
    # Patrimonio neto = Activos (inversiones + propiedades + equity) - Pasivos (deudas)
    @net_worth = @total_assets - @total_debt
    
    # Comparación con mes anterior (para tendencias)
    prev_month = @selected_month - 1.month
    prev_month_start = prev_month.beginning_of_month
    prev_month_end = prev_month.end_of_month
    
    # Calcular deuda del mes anterior
    prev_active_plans = InstallmentPurchase.where(user: current_user)
                                          .active_only
                                          .where('created_at <= ?', prev_month_end)
    prev_total_debt = prev_active_plans.sum { |p| 
      # Calcular remaining_amount manualmente para el mes anterior
      total = p.total_with_interest
      paid = p.installment_payments
               .where('paid_date <= ?', prev_month_end)
               .regular_payments
               .where.not(paid_amount: nil)
               .sum(:paid_amount) || 0
      total - paid
    }
    
    # Calcular inversiones del mes anterior
    prev_active_investments = Investment.where(user: current_user)
                                       .active_only
                                       .where('created_at <= ?', prev_month_end)
    prev_total_investment_balance = prev_active_investments.sum { |inv| 
      # Calcular balance manualmente para el mes anterior
      contributions = inv.investment_movements
                         .where('date <= ?', prev_month_end)
                         .where(movement_type: 'contribution')
                         .sum(:amount) || 0
      withdrawals = inv.investment_movements
                       .where('date <= ?', prev_month_end)
                       .where(movement_type: 'withdrawal')
                       .sum(:amount) || 0
      contributions - withdrawals
    }
    
    prev_net_worth = prev_total_investment_balance - prev_total_debt
    
    # Cambios porcentuales
    @debt_change = prev_total_debt > 0 ? ((@total_debt - prev_total_debt) / prev_total_debt * 100).round(1) : (@total_debt > 0 ? 100 : 0)
    @investment_change = prev_total_investment_balance > 0 ? ((@total_investment_balance - prev_total_investment_balance) / prev_total_investment_balance * 100).round(1) : (@total_investment_balance > 0 ? 100 : 0)
    @net_worth_change = prev_net_worth != 0 ? ((@net_worth - prev_net_worth) / prev_net_worth.abs * 100).round(1) : (@net_worth != 0 ? 100 : 0)
    
    # Inicializar variables de cambio si no se calcularon
    @debt_change ||= 0
    @investment_change ||= 0
    @net_worth_change ||= 0
>>>>>>> 6194f40 (fix: Corregir conteo de transacciones de ingresos para incluir patrón 'ABONO A TU CUENTA')
  end
end
