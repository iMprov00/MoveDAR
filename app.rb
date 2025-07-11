require 'sinatra'
require 'sinatra/activerecord'
require 'roo'

# Модели
require_relative 'models/patient'
require_relative 'models/checkpoint'
require_relative 'models/movement'

set :database, { adapter: "sqlite3", database: "db/hospital_movement.db" }

# Главная страница
get '/' do
  @target_date = params[:date] ? Date.parse(params[:date]) : Date.today
  @patients = Patient.joins(:movements)
                    .where(movements: { movement_date: @target_date })
                    .distinct
                    .order(:full_name)
  erb :index
end

# Загрузка файла
post '/upload' do
  date = Date.parse(params[:date])
  registration = Checkpoint.find_by(name: 'Регистратура')

  if params[:file] && params[:file][:tempfile]
    tempfile = params[:file][:tempfile]
    file_path = tempfile.path
    
    begin
      # Используем Roo::Excelx с явным указанием файла
      excel = Roo::Spreadsheet.open(file_path, extension: :xlsx)
      
      # Определяем последнюю строку
      last_row = excel.last_row
      
      (2..last_row).each do |row|
        # Получаем значения ячеек
        full_name = excel.cell(row, 1).to_s.strip
        time_value = excel.cell(row, 2)
        
        next if full_name.empty?

        # Обработка времени
        time_str = case time_value
                  when Numeric # Excel time format (0.375 = 09:00)
                    seconds = (time_value * 24 * 60 * 60).to_i
                    Time.at(seconds).utc.strftime('%H:%M')
                  when Time, DateTime
                    time_value.strftime('%H:%M')
                  when String
                    # Нормализация строкового времени (9:00 -> 09:00)
                    time_value.gsub(/[^\d]/, '').rjust(4, '0').insert(2, ':')
                  else
                    '00:00' # fallback
                  end

        # Создание или обновление записи
        patient = Patient.find_or_create_by(full_name: full_name)
        
        Movement.create(
          patient: patient,
          checkpoint: registration,
          movement_date: date,
          recorded_at: Time.parse("#{date} #{time_str}"),
          current_time: false
        )
      end
      
      flash[:success] = "Файл успешно загружен"
    rescue StandardError => e
      puts "Ошибка загрузки: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      flash[:error] = "Ошибка загрузки: #{e.message}"
    ensure
      tempfile.close
      tempfile.unlink if tempfile.respond_to?(:unlink)
    end
  end

  redirect "/?date=#{date}"
end