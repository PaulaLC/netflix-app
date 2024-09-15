// custom.js

Shiny.addCustomMessageHandler('close-modal', function(message) {
  setTimeout(function() {
    // Close the modal after the delay
    $('.modal').modal('hide');
  }, message.delay);
});