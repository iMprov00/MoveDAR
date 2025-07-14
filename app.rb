require 'sinatra'
require 'sinatra/activerecord'
require 'roo'
require 'roo-xls'
require 'date'
require 'axlsx'

# Подключение к базе данных
set :database, {adapter: "sqlite3", database: "hospitalization.db"}

# Включаем поддержку сессий
enable :sessions

# Модель
class Appointment < ActiveRecord::Base
  validates :full_name, :appointment_time, :appointment_date, presence: true
end

# Главная страница
get '/' do
  @selected_date = params[:selected_date] ? Date.parse(params[:selected_date]) : Date.today
  @appointments = Appointment.where(appointment_date: @selected_date).order(:appointment_time)
  erb :index
end

post '/upload' do
  @error_message = nil
  @success_message = nil

  if params[:file] && params[:file][:tempfile]
    begin
      file_path = params[:file][:tempfile].path
      
      # Извлекаем данные из Excel
      excel_data, extracted_dates = extract_data_from_excel(file_path)
      
      @selected_date = extracted_dates.first
      
      # Сохраняем в базу данных (теперь данные будут добавляться, а не заменяться)
      save_to_database(excel_data, @selected_date)
      
      # Подсчитываем количество добавленных записей
      added_count = excel_data.count
      @success_message = "Добавлено #{added_count} новых записей на #{@selected_date.strftime('%d.%m.%Y')}!"
    rescue => e
      @error_message = "Ошибка обработки файла: #{e.message}"
      @selected_date ||= Date.today
    end
  else
    @error_message = "Пожалуйста, выберите файл"
    @selected_date = Date.today
  end
  
  @appointments = Appointment.where(appointment_date: @selected_date).order(:appointment_time)
  erb :index
end

private

def extract_data_from_excel(file_path)
  data = []
  dates = []
  xls = Roo::Spreadsheet.open(file_path)
  
  header_row = 7 # Фиксированная строка с заголовками
  
  unless xls.cell(header_row, 3).to_s.include?("Время") && xls.cell(header_row, 4).to_s.include?("Ф.И.О.")
    raise "Не удалось найти заголовки таблицы в строке #{header_row}"
  end
  
  ((header_row + 1)..xls.last_row).each do |row|
    datetime_str = xls.cell(row, 3).to_s.strip
    full_name = xls.cell(row, 4).to_s.strip
    
    next if full_name.empty? && datetime_str.empty?
    
    if datetime_str.match(/(\d{2}\.\d{2}\.\d{4})\s+(\d{2}:\d{2})/)
      date_part = $1
      time_part = $2
      
      begin
        date = Date.strptime(date_part, '%d.%m.%Y')
        dates << date
        
        data << {
          full_name: full_name,
          time: time_part,
          date: date
        }
      rescue ArgumentError => e
        puts "Ошибка парсинга даты: #{e.message}"
        next
      end
    elsif !datetime_str.empty?
      puts "Неверный формат даты/времени в строке #{row}: #{datetime_str}"
    end
  end
  
  if dates.empty?
    raise "В файле не найдено ни одной корректной записи с датой и временем"
  end
  
  [data, dates.uniq]
end

# Удаление одной записи
post '/appointments/:id/delete' do
  # Находим запись по ID
  appointment = Appointment.find_by(id: params[:id])
  
  if appointment
    # Удаляем запись
    appointment.destroy
    @success_message = "Запись успешно удалена"
  else
    @error_message = "Не удалось найти запись для удаления"
  end
  
  # Перенаправляем обратно на ту же страницу
  redirect back
end

# Удаление всех записей на выбранную дату
post '/appointments/delete_all' do
  if params[:date]
    # Преобразуем строку даты в объект Date
    date = Date.parse(params[:date]) rescue nil
    
    if date
      # Удаляем все записи на указанную дату
      count = Appointment.where(appointment_date: date).delete_all
      @success_message = "Удалено #{count} записей"
    else
      @error_message = "Неверный формат даты"
    end
  else
    @error_message = "Дата не указана"
  end
  
  # Перенаправляем обратно на ту же страницу
  redirect back
end

def save_to_database(data, appointment_date)
  data.each do |item|
    # Проверяем, существует ли уже такая запись (по всем параметрам)
    unless Appointment.exists?(
      full_name: item[:full_name],
      appointment_time: item[:time],
      appointment_date: appointment_date
    )
      # Если не существует - создаем новую запись
      Appointment.create(
        full_name: item[:full_name],
        appointment_time: item[:time],
        appointment_date: appointment_date
      )
    end
  end
end



# Страница регистратуры
get '/registration' do
  @selected_date = params[:selected_date] ? Date.parse(params[:selected_date]) : Date.today
  @patients = Appointment.where(appointment_date: @selected_date, registered_at: nil).order(:appointment_time)
  erb :registration
end

post '/register_patient' do
  appointment = Appointment.find(params[:patient_id])
  
  if params[:current_time] == '1'
    registration_time = Time.now.strftime('%H:%M:%S') # Только время
  else
    registration_time = params[:custom_time] + ':00' # Добавляем секунды
  end

  if appointment.update(
    registered_at: Time.now, # Это поле остаётся datetime для истории
    registration_time: registration_time # А это только время
  )
    session[:success_message] = "#{appointment.full_name} успешно отмечен(а) в регистратуре в #{registration_time}"
  else
    session[:error_message] = "Ошибка при отметке пациента"
  end
  
  redirect "/registration?selected_date=#{params[:selected_date]}"
end



post '/add_patient_manually' do
  begin
    appointment_date = Date.strptime(params[:appointment_date], '%d.%m.%Y')
    
    # Создаем запись без данных о регистрации
    patient = Appointment.create(
      full_name: params[:full_name],
      appointment_time: params[:appointment_time],
      appointment_date: appointment_date
      # Не указываем registration_time и registered_at
    )
    
    session[:success_message] = "Пациент #{params[:full_name]} успешно добавлен и ожидает регистрации"
  rescue => e
    session[:error_message] = "Ошибка при добавлении пациента: #{e.message}"
  end
  
  redirect "/registration?selected_date=#{params[:selected_date]}"
end





# Страница кабинета врача
get '/doctor' do
  @selected_date = params[:selected_date] ? Date.parse(params[:selected_date]) : Date.today
  @patients = Appointment.where(appointment_date: @selected_date)
                         .where.not(registered_at: nil)
                         .where(doctor_visited_at: nil)
                         .order(:registration_time)
  erb :doctor
end

# В методе обработки посещения врача (/mark_doctor_visit)
post '/mark_doctor_visit' do
  appointment = Appointment.find(params[:patient_id])
  
  if params[:current_time] == '1'
    visit_time = Time.now.strftime('%H:%M:%S')
  else
    visit_time = params[:custom_time] + ':00'
  end

  if appointment.update(
    doctor_visited_at: Time.now, # Полная дата-время для истории
    doctor_visit_time: visit_time, # Только время
    doctor_notes: params[:notes]
  )
    session[:success_message] = "#{appointment.full_name} успешно отмечен(а) у врача"
  else
    session[:error_message] = "Ошибка при отметке посещения врача"
  end
  
  redirect "/doctor?selected_date=#{params[:selected_date]}"
end







# Страница отчета
get '/report' do
  @selected_date = params[:selected_date] ? Date.parse(params[:selected_date]) : Date.today
  @patients = Appointment.where(appointment_date: @selected_date).order(:appointment_time)

    # Статистика
  @registered_count = @patients.where.not(registered_at: nil).count
  @visited_count = @patients.where.not(doctor_visited_at: nil).count
  @not_registered_count = @patients.where(registered_at: nil).count
  erb :report
end



# Экспорт в Excel
get '/export_excel' do
  date = params[:date] ? Date.parse(params[:date]) : Date.today
  patients = Appointment.where(appointment_date: date).order(:appointment_time)
  
  content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  headers['Content-Disposition'] = "attachment; filename=patients_#{date.strftime('%Y-%m-%d')}.xlsx"
  
  # Создаем Excel файл
  pkg = Axlsx::Package.new
  wb = pkg.workbook
  
  wb.add_worksheet(name: "Пациенты #{date.strftime('%d.%m.%Y')}") do |sheet|
    # Заголовки
    sheet.add_row [
      '№', 'ФИО пациента', 'Запланированное время', 
      'Время регистрации', 'Время приема у врача', 'Статус', 'Примечания'
    ]
    
    # Данные
    patients.each_with_index do |patient, index|
      sheet.add_row [
        index + 1,
        patient.full_name,
        patient.appointment_time,
        patient.registration_time&.strftime('%H:%M:%S') || 'Не зарегистрирован',
        patient.doctor_visit_time&.strftime('%H:%M:%S') || 'Не принят',
        patient.doctor_visited_at ? 'Прием завершен' : (patient.registered_at ? 'Ожидает врача' : 'Не зарегистрирован'),
        patient.doctor_notes
      ]
    end
    
    # Итого
    sheet.add_row ['Итого:', '', '', '', '', '', "#{patients.count} пациентов"]
  end
  
  pkg.to_stream.read
end