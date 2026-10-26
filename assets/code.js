// Adds a "Copy" button to every code block.
(function () {
  document.querySelectorAll('div.highlighter-rouge, figure.highlight').forEach(function (block) {
    var pre = block.querySelector('pre');
    if (!pre) return;
    var lang = (block.className.match(/language-([\w-]+)/) || [])[1];
    var bar = document.createElement('div');
    bar.className = 'code-bar';
    bar.innerHTML = '<span class="code-lang"></span><button type="button" class="code-copy">Copy</button>';
    bar.querySelector('.code-lang').textContent = lang && lang !== 'plaintext' ? lang : '';
    block.insertBefore(bar, block.firstChild);
    var btn = bar.querySelector('button');
    btn.addEventListener('click', function () {
      var text = pre.innerText.replace(/\n$/, '');
      var done = function () { btn.textContent = 'Copied'; setTimeout(function () { btn.textContent = 'Copy'; }, 1500); };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, function () { btn.textContent = 'Select and copy'; });
      } else {
        var r = document.createRange(); r.selectNodeContents(pre);
        var sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(r);
        try { document.execCommand('copy'); done(); } catch (e) { btn.textContent = 'Select and copy'; }
      }
    });
  });
})();
