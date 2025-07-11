document.addEventListener('DOMContentLoaded', function() {
  // Инициализация datepicker
  flatpickr('.datepicker', {
    dateFormat: 'd.m.Y',
    locale: 'ru',
    allowInput: true
  });
});