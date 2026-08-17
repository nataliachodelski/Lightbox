(function () {
  const host = document.getElementById('host');
  const ref = document.getElementById('ref');

  function post(message) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.canvas) {
      window.webkit.messageHandlers.canvas.postMessage(message);
    }
  }

  window.setSource = function (svgText) {
    if (!svgText || svgText.trim() === '') {
      host.innerHTML = '';
      post({ type: 'rendered', width: 0, height: 0 });
      return;
    }

    const parser = new DOMParser();
    const parsedDoc = parser.parseFromString(svgText, 'image/svg+xml');
    const parseError = parsedDoc.querySelector('parsererror');
    if (parseError) {
      post({ type: 'error', message: parseError.textContent || 'Invalid SVG markup' });
      return;
    }

    const svgEl = parsedDoc.documentElement;
    if (!svgEl || svgEl.nodeName.toLowerCase() !== 'svg') {
      post({ type: 'error', message: 'No root <svg> element found' });
      return;
    }

    if (!svgEl.hasAttribute('width') && !svgEl.hasAttribute('height')) {
      svgEl.style.width = '100%';
      svgEl.style.height = '100%';
    }

    host.innerHTML = '';
    host.appendChild(document.adoptNode(svgEl));

    const rect = host.getBoundingClientRect();
    post({ type: 'rendered', width: rect.width, height: rect.height });
  };

  window.setReference = function (config) {
    if (!config || !config.dataURI || !config.visible) {
      ref.style.display = 'none';
      ref.removeAttribute('src');
      return;
    }

    ref.src = config.dataURI;
    ref.style.opacity = config.opacity != null ? config.opacity : 0.5;
    ref.style.left = (config.x || 0) + 'px';
    ref.style.top = (config.y || 0) + 'px';
    ref.style.transform = 'scale(' + (config.scale || 1) + ') rotate(' + (config.rotation || 0) + 'deg)';
    ref.style.display = 'block';
    host.style.zIndex = config.onTop ? '1' : '0';
    ref.style.zIndex = config.onTop ? '2' : '0';
  };
})();
