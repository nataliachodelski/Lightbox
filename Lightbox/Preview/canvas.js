(function () {
  const host = document.getElementById('host');
  const ref = document.getElementById('ref');
  const stage = document.getElementById('stage');
  const artboard = document.getElementById('artboard');

  const MIN_SCALE = 0.05;
  const MAX_SCALE = 32;
  const FIT_MARGIN = 0;

  let scale = 1;
  let panX = 0;
  let panY = 0;
  let hasRenderedOnce = false;

  let refX = 0;
  let refY = 0;
  let refScale = 1;
  let refRotation = 0;
  let refImageWidth = 0;
  let refImageHeight = 0;
  let refHasImage = false;
  let refLocked = false;
  let refSelected = false;

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function post(message) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.canvas) {
      window.webkit.messageHandlers.canvas.postMessage(message);
    }
  }

  function applyTransform() {
    stage.style.transform = 'translate(' + panX + 'px, ' + panY + 'px) scale(' + scale + ')';
  }

  function notifyZoomChanged() {
    post({ type: 'zoomChanged', percent: Math.round(scale * 100) });
  }

  function setScaleAroundPoint(newScale, pointX, pointY) {
    newScale = clamp(newScale, MIN_SCALE, MAX_SCALE);
    if (newScale === scale) return;
    panX = pointX - (newScale * (pointX - panX)) / scale;
    panY = pointY - (newScale * (pointY - panY)) / scale;
    scale = newScale;
    applyTransform();
    notifyZoomChanged();
  }

  function getIntrinsicSize(svgEl) {
    const widthAttr = svgEl.getAttribute('width');
    const heightAttr = svgEl.getAttribute('height');
    const w = widthAttr ? parseFloat(widthAttr) : NaN;
    const h = heightAttr ? parseFloat(heightAttr) : NaN;
    if (!isNaN(w) && !isNaN(h) && w > 0 && h > 0) {
      return { width: w, height: h };
    }
    const viewBox = svgEl.getAttribute('viewBox');
    if (viewBox) {
      const parts = viewBox.trim().split(/[\s,]+/).map(Number);
      if (parts.length === 4 && parts[2] > 0 && parts[3] > 0) {
        return { width: parts[2], height: parts[3] };
      }
    }
    return { width: 300, height: 150 };
  }

  window.setSource = function (svgText) {
    if (!svgText || svgText.trim() === '') {
      host.innerHTML = '';
      artboard.style.width = '0px';
      artboard.style.height = '0px';
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

    const size = getIntrinsicSize(svgEl);
    svgEl.style.width = size.width + 'px';
    svgEl.style.height = size.height + 'px';

    artboard.style.width = size.width + 'px';
    artboard.style.height = size.height + 'px';

    host.innerHTML = '';
    host.appendChild(document.adoptNode(svgEl));

    if (!hasRenderedOnce) {
      hasRenderedOnce = true;
      zoomToFit();
    }

    applyReferenceTransform();

    post({ type: 'rendered', width: size.width, height: size.height });
  };

  function applyReferenceTransform() {
    if (!refHasImage) return;

    const svgEl = host.querySelector('svg');
    const canvasSize = svgEl ? getIntrinsicSize(svgEl) : { width: 0, height: 0 };
    const imageLongest = Math.max(refImageWidth, refImageHeight) || 1;
    const canvasLongest = Math.max(canvasSize.width, canvasSize.height);
    const fitScale = canvasLongest > 0 ? canvasLongest / imageLongest : 1;
    const effectiveScale = fitScale * refScale;

    const centerX = canvasSize.width / 2 + refX;
    const centerY = canvasSize.height / 2 + refY;

    ref.style.left = (centerX - refImageWidth / 2) + 'px';
    ref.style.top = (centerY - refImageHeight / 2) + 'px';
    ref.style.transform = 'scale(' + effectiveScale + ') rotate(' + refRotation + 'deg)';
  }

  function deselectReference() {
    refSelected = false;
    ref.classList.remove('ref-selected');
  }

  window.setReference = function (config) {
    if (!config || !config.dataURI || !config.visible) {
      ref.style.display = 'none';
      ref.removeAttribute('src');
      ref.classList.remove('ref-interactive');
      refHasImage = false;
      if (!config) deselectReference();
      return;
    }

    refX = config.x || 0;
    refY = config.y || 0;
    refScale = config.scale || 1;
    refRotation = config.rotation || 0;
    refImageWidth = config.imageWidth || 0;
    refImageHeight = config.imageHeight || 0;
    refLocked = !!config.locked;
    refHasImage = true;

    ref.src = config.dataURI;
    ref.style.opacity = config.opacity != null ? config.opacity : 0.5;
    ref.style.display = 'block';
    host.style.zIndex = config.onTop ? '1' : '0';
    ref.style.zIndex = config.onTop ? '2' : '0';
    ref.classList.toggle('ref-interactive', !refLocked);
    if (refLocked) deselectReference();
    applyReferenceTransform();
  };

  window.zoomIn = function () {
    setScaleAroundPoint(scale * 1.25, window.innerWidth / 2, window.innerHeight / 2);
  };

  window.zoomOut = function () {
    setScaleAroundPoint(scale / 1.25, window.innerWidth / 2, window.innerHeight / 2);
  };

  window.zoomActualSize = function () {
    setScaleAroundPoint(1, window.innerWidth / 2, window.innerHeight / 2);
  };

  window.setZoomPercent = function (percent) {
    setScaleAroundPoint(percent / 100, window.innerWidth / 2, window.innerHeight / 2);
  };

  window.zoomToFit = function () {
    const svgEl = host.querySelector('svg');
    if (!svgEl) return;
    const size = getIntrinsicSize(svgEl);
    const availW = Math.max(1, window.innerWidth - FIT_MARGIN * 2);
    const availH = Math.max(1, window.innerHeight - FIT_MARGIN * 2);
    const fitScale = Math.min(availW / size.width, availH / size.height);
    scale = clamp(fitScale, MIN_SCALE, MAX_SCALE);
    panX = (window.innerWidth - size.width * scale) / 2;
    panY = (window.innerHeight - size.height * scale) / 2;
    applyTransform();
    notifyZoomChanged();
  };

  window.setBackground = function (mode) {
    artboard.classList.remove('bg-checkerboard', 'bg-white', 'bg-black');
    artboard.style.background = '';
    if (mode === 'checkerboard' || mode === 'white' || mode === 'black') {
      artboard.classList.add('bg-' + mode);
    } else {
      artboard.style.background = mode;
    }
  };

  document.addEventListener('wheel', function (e) {
    e.preventDefault();
    if (e.ctrlKey || e.metaKey) {
      const factor = Math.exp(-e.deltaY * 0.01);
      setScaleAroundPoint(scale * factor, e.clientX, e.clientY);
    } else {
      panX -= e.deltaX;
      panY -= e.deltaY;
      applyTransform();
    }
  }, { passive: false });

  let spaceDown = false;
  let isDragging = false;
  let dragStartX = 0;
  let dragStartY = 0;
  let panStartX = 0;
  let panStartY = 0;

  document.addEventListener('keydown', function (e) {
    if (e.code === 'Space' && !spaceDown) {
      spaceDown = true;
      document.body.classList.add('pan-ready');
    }
  });

  document.addEventListener('keyup', function (e) {
    if (e.code === 'Space') {
      spaceDown = false;
      document.body.classList.remove('pan-ready');
      document.body.classList.remove('panning');
    }
  });

  document.addEventListener('mousedown', function (e) {
    if (spaceDown) {
      isDragging = true;
      dragStartX = e.clientX;
      dragStartY = e.clientY;
      panStartX = panX;
      panStartY = panY;
      document.body.classList.add('panning');
      e.preventDefault();
    }
  });

  document.addEventListener('mousemove', function (e) {
    if (isDragging) {
      panX = panStartX + (e.clientX - dragStartX);
      panY = panStartY + (e.clientY - dragStartY);
      applyTransform();
    }
  });

  document.addEventListener('mouseup', function () {
    if (isDragging) {
      isDragging = false;
      document.body.classList.remove('panning');
    }
  });

  let isDraggingRef = false;
  let refDragStartX = 0;
  let refDragStartY = 0;
  let refStartX = 0;
  let refStartY = 0;

  ref.addEventListener('mousedown', function (e) {
    if (spaceDown || refLocked) return;
    refSelected = true;
    ref.classList.add('ref-selected');
    isDraggingRef = true;
    refDragStartX = e.clientX;
    refDragStartY = e.clientY;
    refStartX = refX;
    refStartY = refY;
    e.stopPropagation();
    e.preventDefault();
  });

  document.addEventListener('mousedown', function (e) {
    if (e.target !== ref) {
      deselectReference();
    }
  });

  document.addEventListener('mousemove', function (e) {
    if (isDraggingRef) {
      refX = refStartX + (e.clientX - refDragStartX) / scale;
      refY = refStartY + (e.clientY - refDragStartY) / scale;
      applyReferenceTransform();
    }
  });

  document.addEventListener('mouseup', function () {
    if (isDraggingRef) {
      isDraggingRef = false;
      post({ type: 'referenceMoved', x: refX, y: refY });
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.code === 'Escape' && refSelected) {
      deselectReference();
      return;
    }
    if (!refSelected || refLocked) return;

    const step = e.shiftKey ? 10 : 1;
    let handled = true;
    if (e.code === 'ArrowLeft') refX -= step;
    else if (e.code === 'ArrowRight') refX += step;
    else if (e.code === 'ArrowUp') refY -= step;
    else if (e.code === 'ArrowDown') refY += step;
    else handled = false;

    if (handled) {
      e.preventDefault();
      applyReferenceTransform();
      post({ type: 'referenceMoved', x: refX, y: refY });
    }
  });

  applyTransform();
})();
