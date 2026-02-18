# Controlador para gestión de Actualizaciones de Precios
# IMPORTANTE: Todas las actualizaciones se crean y acceden solo a través de current_company
# para asegurar el aislamiento multi-tenant
class PriceUpdatesController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_only!
  before_action :set_price_update, only: [:show, :edit, :update, :destroy, :apply, :cancel]

  def index
    @price_updates = PriceUpdate.for_company(current_company)
                                 .includes(:product_presentation, :visit, :store, product_presentation: [:product, :unit_of_measure])
                                 .order(created_at: :desc)
    
    # Filtros
    @price_updates = @price_updates.where(status: params[:status]) if params[:status].present?
    @price_updates = @price_updates.where(visit_id: params[:visit_id]) if params[:visit_id].present?
    @price_updates = @price_updates.where(store_id: params[:store_id]) if params[:store_id].present?
  end

  def show
  end

  def new
    @price_update = PriceUpdate.new
    @price_update.company = current_company
    @product_presentations = current_company.products.active
                                            .joins(:product_presentations)
                                            .where(product_presentations: { active: true })
                                            .includes(:product_presentations, :product_family)
                                            .order(:name)
                                            .distinct
    @visits = Visit.for_company(current_company)
                   .where('scheduled_date >= ?', Date.today)
                   .includes(:user, :store)
                   .order(scheduled_date: :asc)
    @stores = current_company.stores.active.order(:name)
  end

  def create
    @price_update = PriceUpdate.new(price_update_params)
    @price_update.company = current_company
    
    # Validar que los recursos pertenezcan a la compañía
    if @price_update.visit_id.present?
      unless Visit.for_company(current_company).exists?(@price_update.visit_id)
        @price_update.visit = nil
        flash.now[:alert] = "La visita seleccionada no pertenece a tu compañía"
      end
    end
    
    if @price_update.store_id.present?
      unless current_company.stores.exists?(@price_update.store_id)
        @price_update.store = nil
        flash.now[:alert] = "La tienda seleccionada no pertenece a tu compañía"
      end
    end
    
    if @price_update.product_presentation_id.present?
      unless current_company.products.joins(:product_presentations)
                            .where(product_presentations: { id: @price_update.product_presentation_id })
                            .exists?
        @price_update.product_presentation = nil
        flash.now[:alert] = "La presentación del producto no pertenece a tu compañía"
      end
    end
    
    if @price_update.save
      redirect_to price_updates_path, notice: "Actualización de precio creada exitosamente."
    else
      @product_presentations = current_company.products.active
                                              .joins(:product_presentations)
                                              .where(product_presentations: { active: true })
                                              .includes(:product_presentations, :product_family)
                                              .order(:name)
                                              .distinct
      @visits = Visit.for_company(current_company)
                     .where('scheduled_date >= ?', Date.today)
                     .includes(:user, :store)
                     .order(scheduled_date: :asc)
      @stores = current_company.stores.active.order(:name)
      flash.now[:alert] = "Error al crear la actualización: #{@price_update.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product_presentations = current_company.products.active
                                            .joins(:product_presentations)
                                            .where(product_presentations: { active: true })
                                            .includes(:product_presentations, :product_family)
                                            .order(:name)
                                            .distinct
    @visits = Visit.for_company(current_company)
                   .where('scheduled_date >= ?', Date.today)
                   .includes(:user, :store)
                   .order(scheduled_date: :asc)
    @stores = current_company.stores.active.order(:name)
  end

  def update
    @product_presentations = current_company.products.active
                                            .joins(:product_presentations)
                                            .where(product_presentations: { active: true })
                                            .includes(:product_presentations, :product_family)
                                            .order(:name)
                                            .distinct
    @visits = Visit.for_company(current_company)
                   .where('scheduled_date >= ?', Date.today)
                   .includes(:user, :store)
                   .order(scheduled_date: :asc)
    @stores = current_company.stores.active.order(:name)
    
    # Validar que los recursos pertenezcan a la compañía
    if price_update_params[:visit_id].present?
      unless Visit.for_company(current_company).exists?(price_update_params[:visit_id])
        flash.now[:alert] = "La visita seleccionada no pertenece a tu compañía"
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    if price_update_params[:store_id].present?
      unless current_company.stores.exists?(price_update_params[:store_id])
        flash.now[:alert] = "La tienda seleccionada no pertenece a tu compañía"
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    if @price_update.update(price_update_params)
      redirect_to price_updates_path, notice: "Actualización de precio actualizada exitosamente."
    else
      flash.now[:alert] = "Error al actualizar: #{@price_update.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @price_update.destroy
      redirect_to price_updates_path, notice: "Actualización de precio eliminada exitosamente."
    else
      redirect_to price_updates_path, alert: "Error al eliminar la actualización."
    end
  end

  def apply
    if @price_update.pending?
      @price_update.apply!
      redirect_to price_updates_path, notice: "Actualización de precio marcada como aplicada."
    else
      redirect_to price_updates_path, alert: "Solo se pueden aplicar actualizaciones pendientes."
    end
  end

  def cancel
    if @price_update.pending?
      @price_update.cancel!
      redirect_to price_updates_path, notice: "Actualización de precio cancelada."
    else
      redirect_to price_updates_path, alert: "Solo se pueden cancelar actualizaciones pendientes."
    end
  end

  def import
  end

  def download_template
    require 'write_xlsx' unless defined?(WriteXLSX)
    require 'stringio' unless defined?(StringIO)
    
    # Crear un archivo temporal en memoria
    io = StringIO.new
    workbook = WriteXLSX.new(io)
    
    # Crear hoja de plantilla
    worksheet = workbook.add_worksheet('Plantilla Precios')
    
    # Estilos (write_xlsx usa índices de formato)
    header_format = workbook.add_format(
      bold: 1,
      bg_color: '#4472C4',
      color: '#FFFFFF',
      align: 'center',
      valign: 'vcenter'
    )
    
    required_format = workbook.add_format(
      bg_color: '#FFE699',
      align: 'center'
    )
    
    optional_format = workbook.add_format(
      bg_color: '#D9D9D9',
      align: 'center'
    )
    
    bold_format = workbook.add_format(bold: 1)
    
    # Agregar headers
    worksheet.write_row(0, 0, [
      "Codigo_Cadena",
      "Codigo_Formato", 
      "Codigo_Producto",
      "Codigo_Presentacion",
      "Nuevo_Precio",
      "Notas"
    ], header_format)
    
    # Agregar filas de ejemplo
    worksheet.write_row(1, 0, ["WAL", "WAL_SUP", "PROD001", "PRES001", "25.50", "Promoción verano"], 
                       [required_format, required_format, required_format, required_format, required_format, optional_format])
    worksheet.write_row(2, 0, ["SOR", "SOR_HIP", "PROD002", "PRES002", "30.00", ""],
                       [required_format, required_format, required_format, required_format, required_format, optional_format])
    
    # Ajustar ancho de columnas
    worksheet.set_column(0, 0, 15) # Codigo_Cadena
    worksheet.set_column(1, 1, 15) # Codigo_Formato
    worksheet.set_column(2, 2, 18) # Codigo_Producto
    worksheet.set_column(3, 3, 20) # Codigo_Presentacion
    worksheet.set_column(4, 4, 12) # Nuevo_Precio
    worksheet.set_column(5, 5, 30) # Notas
    
    # Crear hoja de códigos disponibles
    codes_sheet = workbook.add_worksheet('Códigos Disponibles')
    
    codes_sheet.write(0, 0, "Códigos de Cadenas y Formatos Disponibles", header_format)
    codes_sheet.write(2, 0, "Cadenas:", bold_format)
    
    # Códigos de cadenas
    chains_data = [
      ["WAL", "Walmart"],
      ["SOR", "Soriana"],
      ["CHD", "Chedraui"],
      ["COM", "La Comer"],
      ["HEB", "H-E-B"],
      ["FEM", "FEMSA"],
      ["LEY", "Casa Ley"],
      ["SMT", "S-Mart"]
    ]
    
    chains_data.each_with_index do |row, idx|
      codes_sheet.write_row(3 + idx, 0, row)
    end
    
    row_idx = 12
    codes_sheet.write(row_idx, 0, "Formatos Walmart (WAL):", bold_format)
    walmart_formats = [
      ["WAL_SUP", "Walmart Supercenter"],
      ["WAL_EXP", "Walmart Express"],
      ["WAL_BOD", "Bodega Aurrera"],
      ["WAL_SAM", "Sam's Club"]
    ]
    walmart_formats.each_with_index do |row, idx|
      codes_sheet.write_row(row_idx + 1 + idx, 0, row)
    end
    
    row_idx += 6
    codes_sheet.write(row_idx, 0, "Formatos Soriana (SOR):", bold_format)
    soriana_formats = [
      ["SOR_HIP", "Soriana Híper"],
      ["SOR_SUP", "Soriana Súper"],
      ["SOR_MER", "Soriana Mercado"],
      ["SOR_CIT", "City Club"]
    ]
    soriana_formats.each_with_index do |row, idx|
      codes_sheet.write_row(row_idx + 1 + idx, 0, row)
    end
    
    row_idx += 6
    codes_sheet.write(row_idx, 0, "Formatos Chedraui (CHD):", bold_format)
    chedraui_formats = [
      ["CHD_STD", "Chedraui"],
      ["CHD_SEL", "Selecto Chedraui"],
      ["CHD_SUP", "Súper Chedraui"],
      ["CHD_CHE", "Súper Che / Súpercito"]
    ]
    chedraui_formats.each_with_index do |row, idx|
      codes_sheet.write_row(row_idx + 1 + idx, 0, row)
    end
    
    row_idx += 6
    codes_sheet.write(row_idx, 0, "Nota: Consulta la documentación completa para ver todos los códigos disponibles.")
    
    # Ajustar ancho de columnas en la hoja de códigos
    codes_sheet.set_column(0, 0, 25)
    codes_sheet.set_column(1, 1, 30)
    
    workbook.close
    
    # Enviar el archivo
    send_data io.string,
              filename: "plantilla_actualizacion_precios.xlsx",
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

  def process_import
    unless params[:file].present?
      redirect_to import_price_updates_path, alert: "Por favor selecciona un archivo."
      return
    end

    begin
      require 'roo' unless defined?(Roo)
      file = params[:file]
      spreadsheet = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      sheet = spreadsheet.sheet(0)
      
      headers = sheet.row(1).map(&:to_s).map(&:strip)
      
      # Validar headers
      required_headers = ['codigo_cadena', 'codigo_formato', 'codigo_producto', 'codigo_presentacion', 'nuevo_precio']
      missing_headers = required_headers - headers.map(&:downcase)
      
      if missing_headers.any?
        redirect_to import_price_updates_path, 
          alert: "Faltan las siguientes columnas: #{missing_headers.join(', ')}"
        return
      end
      
      # Mapear índices de columnas
      chain_code_idx = headers.map(&:downcase).index('codigo_cadena')
      format_code_idx = headers.map(&:downcase).index('codigo_formato')
      product_code_idx = headers.map(&:downcase).index('codigo_producto')
      presentation_code_idx = headers.map(&:downcase).index('codigo_presentacion')
      price_idx = headers.map(&:downcase).index('nuevo_precio')
      notes_idx = headers.map(&:downcase).index('notas')
      
      success_count = 0
      error_count = 0
      errors = []
      
      # Procesar cada fila (empezando desde la 2, ya que la 1 son los headers)
      (2..sheet.last_row).each do |row_num|
        row = sheet.row(row_num)
        
        # Saltar filas vacías
        next if row.all?(&:blank?)
        
        chain_code = row[chain_code_idx]&.to_s&.strip
        format_code = row[format_code_idx]&.to_s&.strip
        product_code = row[product_code_idx]&.to_s&.strip
        presentation_code = row[presentation_code_idx]&.to_s&.strip
        price_str = row[price_idx]&.to_s&.strip
        notes = notes_idx ? row[notes_idx]&.to_s&.strip : nil
        
        # Validar campos requeridos
        if chain_code.blank? || format_code.blank? || product_code.blank? || presentation_code.blank? || price_str.blank?
          error_count += 1
          errors << "Fila #{row_num}: Faltan campos requeridos"
          next
        end
        
        # Validar y convertir precio
        begin
          new_price = BigDecimal(price_str)
          if new_price <= 0
            error_count += 1
            errors << "Fila #{row_num}: El precio debe ser mayor a 0"
            next
          end
        rescue
          error_count += 1
          errors << "Fila #{row_num}: Precio inválido: #{price_str}"
          next
        end
        
        # Buscar cadena por código
        chain = current_company.chains.active.find_by(code: chain_code)
        unless chain
          error_count += 1
          errors << "Fila #{row_num}: Cadena con código '#{chain_code}' no encontrada"
          next
        end
        
        # Buscar formato por código
        format = chain.formats.active.find_by(code: format_code)
        unless format
          error_count += 1
          errors << "Fila #{row_num}: Formato con código '#{format_code}' no encontrado para la cadena '#{chain_code}'"
          next
        end
        
        # Buscar producto
        product = current_company.products.active.find_by(code: product_code)
        unless product
          error_count += 1
          errors << "Fila #{row_num}: Producto con código '#{product_code}' no encontrado"
          next
        end
        
        # Buscar presentación (primero por código, luego por barcode)
        presentation = product.product_presentations.active.find_by(code: presentation_code) ||
                      product.product_presentations.active.find_by(barcode: presentation_code)
        unless presentation
          error_count += 1
          errors << "Fila #{row_num}: Presentación con código '#{presentation_code}' no encontrada para el producto '#{product_code}'"
          next
        end
        
        # Buscar todas las tiendas que coincidan con cadena y formato
        stores = current_company.stores.active
                                .where(chain_id: chain.id, format_id: format.id)
        
        if stores.empty?
          error_count += 1
          errors << "Fila #{row_num}: No se encontraron tiendas para la combinación Cadena: '#{chain_code}', Formato: '#{format_code}'"
          next
        end
        
        # Crear actualizaciones para cada tienda
        stores.each do |store|
          price_update = PriceUpdate.new(
            company: current_company,
            product_presentation: presentation,
            store: store,
            new_price: new_price,
            notes: notes,
            status: :pending
          )
          
          if price_update.save
            success_count += 1
          else
            error_count += 1
            errors << "Fila #{row_num} (Tienda: #{store.name}): #{price_update.errors.full_messages.join(', ')}"
          end
        end
      end
      
      if success_count > 0
        notice_msg = "#{success_count} actualización(es) creada(s) exitosamente."
        notice_msg += " #{error_count} error(es)." if error_count > 0
        redirect_to price_updates_path, notice: notice_msg
      else
        redirect_to import_price_updates_path, 
          alert: "No se pudo crear ninguna actualización. Errores: #{errors.first(5).join('; ')}"
      end
      
      # Guardar errores en flash si hay muchos
      if errors.any? && errors.count <= 10
        flash[:import_errors] = errors
      end
      
    rescue => e
      redirect_to import_price_updates_path, 
        alert: "Error al procesar el archivo: #{e.message}"
    end
  end

  private

  def set_price_update
    @price_update = PriceUpdate.for_company(current_company).find(params[:id])
  end

  def price_update_params
    params.require(:price_update).permit(:product_presentation_id, :new_price, :visit_id, :store_id, :notes)
  end
end
