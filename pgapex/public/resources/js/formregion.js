$(document).ready(function() {
    $.get('/index.php/api/page/page/37', function(data) {
        console.log(data);
    });
});
