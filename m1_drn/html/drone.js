
document.addEventListener('DOMContentLoaded', () => {
  const hud           = document.getElementById('hud');
  const droneSound    = document.getElementById('drone-sound');
  const speedHEl      = document.getElementById('speed-h');
  const speedVEl      = document.getElementById('speed-v');
  const altitudeEl    = document.getElementById('altitude');
  const distanceEl    = document.getElementById('distance');
  const coordsEl      = document.getElementById('coords');
  const recTimerEl    = document.getElementById('rec-timer');
  const signalFillEl  = document.getElementById('signal-fill');
  const signalTextEl  = document.getElementById('signal');
  const infoPanel     = document.getElementById('info-panel');
  const filterButtons = document.querySelectorAll('#filters .flt');

  droneSound.loop = true;

  filterButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      filterButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  window.addEventListener('message', evt => {
    const d = evt.data;

    switch (d.action) {
      case 'showHUD':
        hud.classList.remove('hidden');
        infoPanel.classList.remove('visible');
        infoPanel.innerHTML = '';
        droneSound.play().catch(()=>{});
        break;

      case 'hideHUD':
        hud.classList.add('hidden');
        droneSound.pause();
        droneSound.currentTime = 0;
        infoPanel.classList.remove('visible');
        infoPanel.innerHTML = '';
        break;

      case 'updateTelemetry':
        speedHEl.textContent   = d.speedH;
        speedVEl.textContent   = d.speedV;
        altitudeEl.textContent = d.alt;
        distanceEl.textContent = d.dist;
        coordsEl.textContent   = d.coords;
        break;

      case 'updateRecording':
        recTimerEl.textContent = d.time;
        break;

      case 'updateSignal':
        signalFillEl.style.width = d.signal + '%';
        signalTextEl.textContent = d.signal + '%';
        break;

      case 'setMode':
        infoPanel.innerHTML = `
          <div class="info-header">${d.mode.toUpperCase()}</div>
        `;
        infoPanel.classList.add('visible');
        break;

      case 'showPlateInfo':
        infoPanel.innerHTML = `
          <div class="info-header">VEHICLE</div>
          <div class="info-row"><span class="label">Plate:</span> <strong>${d.plate}</strong></div>
          <div class="info-row"><span class="label">Owner:</span> <strong>${d.owner}</strong></div>
        `;
        infoPanel.classList.add('visible');
        break;

      case 'showPlayerInfo':
        if (d.data) {
          infoPanel.innerHTML = `
            <div class="info-header">PLAYER</div>
            <div class="info-row"><span class="label">Name:</span> <strong>${d.data.name}</strong></div>
            <div class="info-row"><span class="label">DOB:</span> <strong>${d.data.dob}</strong></div>
            <div class="info-row"><span class="label">Job:</span> <strong>${d.data.job}</strong></div>
          `;
        } else {
          infoPanel.innerHTML = `
            <div class="info-header">PLAYER</div>
            <div class="info-row">Data unavailable</div>
          `;
        }
        infoPanel.classList.add('visible');
        break;
    }
  });
});
