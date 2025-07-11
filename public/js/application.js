document.addEventListener('DOMContentLoaded', function() {
  // Инициализация datepicker для формы загрузки
  flatpickr('.datepicker', {
    dateFormat: 'd.m.Y',
    locale: 'ru',
    allowInput: true,
    defaultDate: document.getElementById('date')?.value || new Date()
  });

  // Инициализация datepicker для фильтрации
  const dateFilter = flatpickr('#date-filter', {
    dateFormat: 'd.m.Y',
    locale: 'ru',
    allowInput: true,
    defaultDate: document.getElementById('date-filter')?.value || new Date(),
    onChange: function(selectedDates, dateStr) {
      const url = this.element.dataset.url;
      const selectedDate = dateStr.split('.').reverse().join('-');
      window.location.href = `${url}?selected_date=${selectedDate}`;
    }
  });
});