document.addEventListener('DOMContentLoaded', function() {
  // Получаем текущее значение даты из input
  const initialDate = document.getElementById('date-filter')?.value;
  
  // Инициализация datepicker для фильтрации
  const dateFilter = flatpickr('#date-filter', {
    dateFormat: 'd.m.Y',
    locale: 'ru',
    allowInput: true,
    defaultDate: initialDate, // Устанавливаем дату из значения input
    onChange: function(selectedDates, dateStr) {
      const url = this.element.dataset.url;
      const selectedDate = dateStr.split('.').reverse().join('-');
      window.location.href = `${url}?selected_date=${selectedDate}`;
    }
  });

  // Для других datepicker'ов на странице (если есть)
  flatpickr('.datepicker:not(#date-filter)', {
    dateFormat: 'd.m.Y',
    locale: 'ru',
    allowInput: true,
    defaultDate: initialDate // Используем ту же дату
  });
});

function confirmDelete() {
  return confirm("Вы уверены, что хотите удалить эту запись?");
}

function confirmDeleteAll() {
  const date = document.querySelector('input[name="date"]').value;
  return confirm(`Вы уверены, что хотите удалить ВСЕ записи на ${date}?`);
}

// Управление полем времени в регистратуре
document.addEventListener('DOMContentLoaded', function() {
  const timeCheckbox = document.getElementById('current-time-checkbox');
  const timeInput = document.getElementById('time-input');
  
  if (timeCheckbox && timeInput) {
    timeCheckbox.addEventListener('change', function() {
      timeInput.disabled = this.checked;
      if (this.checked) {
        timeInput.value = new Date().toTimeString().substring(0, 5);
      }
    });
  }
  
  // Инициализация datepicker для страницы регистратуры
  const dateFilter = document.getElementById('date-filter');
  if (dateFilter) {
    flatpickr(dateFilter, {
      dateFormat: 'd.m.Y',
      locale: 'ru',
      allowInput: true,
      defaultDate: dateFilter.value,
      onChange: function(selectedDates, dateStr) {
        const url = this.element.dataset.url;
        const selectedDate = dateStr.split('.').reverse().join('-');
        window.location.href = `${url}?selected_date=${selectedDate}`;
      }
    });
  }
});




// Для страницы кабинета врача
document.addEventListener('DOMContentLoaded', function() {
  // Управление временем (аналогично регистратуре)
  const timeCheckbox = document.getElementById('current-time-checkbox');
  const timeInput = document.getElementById('time-input');
  
  if (timeCheckbox && timeInput) {
      timeCheckbox.addEventListener('change', function() {
        timeInput.disabled = this.checked;
        if (this.checked) {
          const now = new Date();
          timeInput.value = now.getHours().toString().padStart(2, '0') + ':' + 
                            now.getMinutes().toString().padStart(2, '0');
        }
      });
  }
  
  // Инициализация datepicker для страницы кабинета
  const doctorDateFilter = document.getElementById('date-filter');
  if (doctorDateFilter) {
    flatpickr(doctorDateFilter, {
      dateFormat: 'd.m.Y',
      locale: 'ru',
      allowInput: true,
      defaultDate: doctorDateFilter.value,
      onChange: function(selectedDates, dateStr) {
        const url = this.element.dataset.url;
        const selectedDate = dateStr.split('.').reverse().join('-');
        window.location.href = `${url}?selected_date=${selectedDate}`;
      }
    });
  }
});




// Для страницы отчета
document.addEventListener('DOMContentLoaded', function() {
  // Инициализация datepicker
  const reportDateFilter = document.getElementById('date-filter');
  if (reportDateFilter) {
    flatpickr(reportDateFilter, {
      dateFormat: 'd.m.Y',
      locale: 'ru',
      allowInput: true,
      defaultDate: reportDateFilter.value,
      onChange: function(selectedDates, dateStr) {
        const url = this.element.dataset.url;
        const selectedDate = dateStr.split('.').reverse().join('-');
        window.location.href = `${url}?selected_date=${selectedDate}`;
      }
    });
  }

  // Кнопка печати
  const printBtn = document.getElementById('print-report');
  if (printBtn) {
    printBtn.addEventListener('click', function() {
      window.print();
    });
  }
});