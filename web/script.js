const wrapper = document.getElementById('wrapper');

let CFG = null;

// ---------- helpers ----------
function post(name, data = {}) {
    const resName = window.GetParentResourceName ? GetParentResourceName() : 'advanced_starterpackV2';
    fetch(`https://${resName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

function formatMoney(n) {
    return '$' + Number(n).toLocaleString('en-US');
}

// ---------- rendering ----------
function makeTile(t, itemImages) {
    const el = document.createElement('div');
    el.className = 'tile';

    const count = document.createElement('span');
    count.className = `tile-count ${t.cash ? 'cash' : 'qty'}`;
    count.textContent = t.count;

    const iconWrap = document.createElement('div');
    iconWrap.className = 'tile-icon';

    // Item tiles use a real inventory image (with emoji fallback on error).
    // Money/Bank tiles always use their emoji.
    if (t.item && itemImages && itemImages.enabled) {
        const img = document.createElement('img');
        img.className = 'tile-img';
        img.src = (itemImages.path || '') + t.name + (itemImages.ext || '.png');
        img.alt = t.label;
        img.onerror = () => { iconWrap.textContent = t.icon || '📦'; };
        iconWrap.appendChild(img);
    } else {
        iconWrap.textContent = t.icon || '📦';
    }

    const label = document.createElement('div');
    label.className = 'tile-label';
    label.textContent = t.label;

    el.appendChild(count);
    el.appendChild(iconWrap);
    el.appendChild(label);
    return el;
}

function renderRewards(cfg) {
    const grid = document.getElementById('rewards-grid');
    grid.innerHTML = '';

    const tiles = [];

    // Money + Bank tiles (shown as green $ amounts, always emoji)
    if (cfg.money.cash > 0) {
        tiles.push({ count: formatMoney(cfg.money.cash), cash: true, icon: '💵', label: 'Money', item: false });
    }
    if (cfg.money.bank > 0) {
        tiles.push({ count: formatMoney(cfg.money.bank), cash: true, icon: '🏦', label: 'Bank', item: false });
    }
    // Item tiles (use inventory images)
    cfg.items.forEach((it) => {
        tiles.push({ count: `${it.count}x`, cash: false, icon: it.icon || '📦', label: it.label, name: it.name, item: true });
    });

    tiles.forEach((t) => grid.appendChild(makeTile(t, cfg.itemImages)));

    // rewards count text
    const totalRewards = cfg.items.length + (cfg.money.cash > 0 ? 1 : 0) + (cfg.money.bank > 0 ? 1 : 0);
    document.getElementById('rewards-count').textContent = `${totalRewards} rewards ready to claim`;
}

function renderVehicleImage(cfg) {
    const img = document.getElementById('vehicle-img');
    const art = document.getElementById('vehicle-art');
    const src = (cfg.vehicle.image || '').trim();

    // Show the built-in CSS silhouette if no image is configured / it fails to load.
    const showFallback = () => {
        img.classList.add('hidden');
        art.classList.remove('hidden');
    };

    if (!src) {
        showFallback();
        return;
    }

    img.onerror = showFallback;
    img.onload = () => {
        art.classList.add('hidden');
        img.classList.remove('hidden');
    };
    img.src = src;
}

function renderVehicle(cfg) {
    const card = document.getElementById('vehicle-card');
    if (!cfg.vehicle.enabled) {
        card.classList.add('hidden');
        return;
    }
    card.classList.remove('hidden');
    document.getElementById('vehicle-badge').textContent = cfg.text.VehicleBadge || 'Starter Vehicle';
    document.getElementById('vehicle-name').textContent = cfg.vehicle.label || 'Starter Vehicle';
    document.getElementById('vehicle-sub').textContent =
        `${cfg.vehicle.class || ''}${cfg.vehicle.class ? ' · ' : ''}${cfg.vehicle.seats || 0} seats`;
    renderVehicleImage(cfg);
}

function renderHeader(cfg) {
    document.getElementById('title').textContent = cfg.text.Title;
    document.getElementById('subtitle').textContent = cfg.text.Subtitle;
    document.getElementById('package-badge').textContent = cfg.text.PackageBadge || 'Starter Package';
}

// ---------- claim states ----------
function applyState(state) {
    const collectBtn = document.getElementById('collect-btn');
    const vehicleBtn = document.getElementById('claim-vehicle-btn');

    if (state.package) {
        collectBtn.textContent = 'Collected';
        collectBtn.classList.add('claimed');
    } else {
        collectBtn.textContent = 'Collect Package';
        collectBtn.classList.remove('claimed');
    }

    if (state.vehicle) {
        vehicleBtn.textContent = 'Claimed';
        vehicleBtn.classList.add('claimed');
    } else {
        vehicleBtn.textContent = 'Claim Vehicle';
        vehicleBtn.classList.remove('claimed');
    }
}

// ---------- open / close ----------
function open(data) {
    CFG = data;
    renderHeader(data);
    renderRewards(data);
    renderVehicle(data);
    applyState(data.state || { package: false, vehicle: false });
    wrapper.classList.remove('hidden');
}

function close() {
    wrapper.classList.add('hidden');
    post('close');
}

// ---------- events ----------
document.getElementById('collect-btn').addEventListener('click', () => {
    const btn = document.getElementById('collect-btn');
    if (btn.classList.contains('claimed')) return;
    // Dim + disable immediately so it can't be clicked again while the
    // server processes the claim (the state sync then keeps it locked).
    btn.textContent = 'Collected';
    btn.classList.add('claimed');
    post('claimPackage');
});

document.getElementById('claim-vehicle-btn').addEventListener('click', () => {
    const btn = document.getElementById('claim-vehicle-btn');
    if (btn.classList.contains('claimed')) return;
    btn.textContent = 'Claimed';
    btn.classList.add('claimed');
    post('claimVehicle');
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !wrapper.classList.contains('hidden')) close();
});

window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.action) {
        case 'open':
            open(data);
            break;
        case 'close':
            wrapper.classList.add('hidden');
            break;
        case 'state':
            if (CFG) CFG.state = data.state;
            applyState(data.state);
            break;
    }
});
