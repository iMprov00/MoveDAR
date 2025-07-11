require 'sinatra'
require 'sinatra/activerecord'
require 'roo'
require 'roo-xls'
require 'date'

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
  @appointments = Appointment.order(:appointment_date, :appointment_time)
  erb :index
end

# Обработка загрузки файла
post '/upload' do
  if params[:file] && params[:file][:tempfile] && params[:date]
    begin
      file_path = params[:file][:tempfile].path
      appointment_date = Date.parse(params[:date])
      
      # Извлекаем данные из Excel
      excel_data = extract_data_from_excel(file_path)
      
      # Сохраняем в базу данных
      save_to_database(excel_data, appointment_date)
      
      @success_message = "Данные успешно загружены!"
    rescue => e
      @error_message = "Ошибка: #{e.message}"
    end
  else
    @error_message = "Пожалуйста, выберите дату и файл"
  end
  
  @appointments = Appointment.order(:appointment_date, :appointment_time)
  erb :index
end

private

def extract_data_from_excel(file_path)
  data = []
  xls = Roo::Spreadsheet.open(file_path)
  
  (8..xls.last_row).each do |row|
    full_name = xls.cell(row, 4)  # Столбец D
    time = xls.cell(row, 3)       # Столбец C
    
    data << { full_name: full_name, time: time } if full_name && time
  end
  
  data
end

def save_to_database(data, appointment_date)
  data.each do |item|
    next if Appointment.exists?(
      full_name: item[:full_name],
      appointment_time: item[:time],
      appointment_date: appointment_date
    )
    
    Appointment.create(
      full_name: item[:full_name],
      appointment_time: item[:time],
      appointment_date: appointment_date
    )
  end
end