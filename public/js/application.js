document.addEventListener('DOMContentLoaded', function() {
  setupTimeControls();// Проверка загрузки jQuery (необходим для Select2)
  function checkJQuery() {
    return new Promise((resolve) => {
      if (window.jQuery) {
        resolve();
      } else {
        const script = document.createElement('script');
        script.src = 'https://code.jquery.com/jquery-3.6.0.min.js';
        script.onload = resolve;
        document.head.appendChild(script);
      }
    });
  }

  // Инициализация datepicker
  function initializeDatepickers() {
    if (typeof flatpickr !== 'undefined') {
      const dateFilters = document.querySelectorAll('.datepicker');
      dateFilters.forEach(filter => {
        // Проверяем, не инициализирован ли уже
        if (!filter._flatpickr) {
          flatpickr(filter, {
            dateFormat: 'd.m.Y',
            locale: 'ru',
            allowInput: true,
            clickOpens: true, // Важно: разрешаем открытие по клику
            defaultDate: filter.value,
            onChange: function(selectedDates, dateStr) {
              const url = this.element.dataset.url;
              const selectedDate = dateStr.split('.').reverse().join('-');
              if (url) {
                window.location.href = `${url}?selected_date=${selectedDate}`;
              }
            }
          });
        }
      });
    } else {
      console.warn('Flatpickr not loaded');
    }
  }

  // Инициализация Select2
  function initializeSelect2() {
    if (typeof $ !== 'undefined' && $.fn.select2) {
      $('.patient-select').each(function() {
        if (!$(this).hasClass('select2-hidden-accessible')) {
          $(this).select2({
            language: 'ru',
            theme: 'bootstrap-5',
            placeholder: 'Начните вводить имя пациента',
            allowClear: true,
            width: '100%',
            minimumInputLength: 1,
            dropdownParent: $(this).parent(),
            sorter: function(data) {
              return data.sort(function(a, b) {
                return a.text.localeCompare(b.text);
              });
            }
          });
        }
      });

      $(document).on('select2:open', () => {
        setTimeout(() => {
          document.querySelector('.select2-search__field')?.focus();
        }, 100);
      });
    }
  }

function setupTimeControls() {
  const timeCheckbox = document.getElementById('current-time-checkbox');
  const timeInput = document.getElementById('time-input');
  
  if (timeCheckbox && timeInput) {
    // Инициализация начального состояния
    timeInput.disabled = timeCheckbox.checked;
    if (timeCheckbox.checked) {
      timeInput.value = new Date().toTimeString().substring(0, 5);
    }
    
    // Обработчик изменения состояния чекбокса
    timeCheckbox.addEventListener('change', function() {
      timeInput.disabled = this.checked;
      if (this.checked) {
        // Установка текущего времени при включении чекбокса
        timeInput.value = new Date().toTimeString().substring(0, 5);
      }
    });
    
    // Дополнительно: обновление времени при фокусе на поле ввода
    timeInput.addEventListener('focus', function() {
      if (!timeCheckbox.checked) {
        this.value = new Date().toTimeString().substring(0, 5);
      }
    });
  }
}

  // Функции для страницы регистратуры
  function initializeRegistrationPage() {


    // AJAX-добавление пациента
    const addPatientForm = document.querySelector('form[action="/add_patient_manually"]');
    if (addPatientForm) {
      addPatientForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        fetch(this.action, {
          method: 'POST',
          body: new FormData(this),
          headers: {
            'Accept': 'application/json'
          }
        })
        .then(response => response.json())
        .then(data => {
          if (data.success) {
            const collapse = bootstrap.Collapse.getInstance(document.getElementById('addPatientForm'));
            if (collapse) collapse.hide();
            
            showAlert('Пациент успешно добавлен', 'success');
            
            setTimeout(() => {
              window.location.reload();
            }, 1000);
          } else {
            showAlert(data.error || 'Ошибка при добавлении пациента', 'danger');
          }
        })
        .catch(error => {
          showAlert('Ошибка сети: ' + error.message, 'danger');
        });
      });
    }
  }

  // Функция показа уведомлений
  function showAlert(message, type) {
    const alert = document.createElement('div');
    alert.className = `alert alert-${type} alert-dismissible fade show`;
    alert.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    const container = document.getElementById('alerts-container') || document.body;
    container.prepend(alert);
    
    setTimeout(() => {
      const bsAlert = bootstrap.Alert.getInstance(alert);
      if (bsAlert) bsAlert.close();
    }, 5000);
  }

// Анимация счетчиков
function animateCounters() {
  const counters = document.querySelectorAll('.stat-content h3');
  
  counters.forEach(counter => {
    const target = +counter.innerText;
    let count = 0;
    counter.innerText = '0';
    
    const updateCounter = () => {
      const increment = target / 50; // Скорость анимации
      count += increment;
      
      if (count < target) {
        counter.innerText = Math.ceil(count);
        requestAnimationFrame(updateCounter);
      } else {
        counter.innerText = target;
      }
    };
    
    updateCounter();
  });
}

  // Главная функция инициализации
  async function initializeApp() {
    try {
      await checkJQuery(); // Ждем загрузки jQuery при необходимости
      
      // Инициализация общих компонентов
      initializeDatepickers();
      initializeSelect2();
      
      if (document.querySelectorAll('.stat-content h3').length) {
        animateCounters();
      }
      
      // Инициализация специфичных для страницы компонентов
      if (document.querySelector('body[data-page="registration"]')) {
        initializeRegistrationPage();
      }
      
      // Кнопка печати
      const printBtn = document.getElementById('print-report');
      if (printBtn) {
        printBtn.addEventListener('click', window.print);
      }
    } catch (error) {
      console.error('Initialization error:', error);
    }
  }

  // Запуск приложения
  initializeApp();
});

// Глобальные функции подтверждения
function confirmDelete() {
  return confirm("Вы уверены, что хотите удалить эту запись?");
}

function confirmDeleteAll() {
  const date = document.querySelector('input[name="date"]').value;
  return confirm(`Вы уверены, что хотите удалить ВСЕ записи на ${date}?`);
}