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