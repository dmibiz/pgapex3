$(document).ready(function() {
    $('select[readonly] option:not(:selected)').attr('disabled', true);
    $(':radio[readonly]:not(:checked)').attr('disabled', true);

    $('input[type="checkbox"]').on('click keyup keypress keydown', function (event) {
        if($(this).is('[readonly]')) { return false; }
    });
});
