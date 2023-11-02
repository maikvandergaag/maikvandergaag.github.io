var divs = document.querySelectorAll('.sidebar');

for (var i = 0; i < divs.length; i++) {
    divs[i].innerHTML += '<iframe src="https://github.com/sponsors/maikvandergaag/button" title="Sponsor maikvandergaag" height="32" width="114" style="border: 0; border-radius: 6px;"></iframe>';
}
