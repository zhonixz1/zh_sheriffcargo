const app = document.getElementById("app");
const title = document.getElementById("title");
const subtitle = document.getElementById("subtitle");
const routeSelect = document.getElementById("routeSelect");
const marketList = document.getElementById("marketList");
const selectedList = document.getElementById("selectedList");
const marketCount = document.getElementById("marketCount");
const totalCount = document.getElementById("totalCount");
const cancelBtn = document.getElementById("cancelBtn");
const startBtn = document.getElementById("startBtn");

let state = {
    items: [],
    selected: {},
    maxTotalItems: 0,
    maxPerItem: 1,
    emptySelectionText: "The chest is empty"
};

function postNui(eventName, payload = {}) {
    return fetch(`https://${GetParentResourceName()}/${eventName}`, {
        method: "POST",
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: JSON.stringify(payload)
    });
}

function clampAmount(value, max) {
    const amount = Math.floor(Number(value) || 0);
    return Math.max(0, Math.min(amount, max));
}

function getTotalAmount() {
    return Object.values(state.selected).reduce((total, entry) => total + entry.amount, 0);
}

function getSelectedArray() {
    return Object.values(state.selected)
        .filter((entry) => entry.amount > 0)
        .map((entry) => ({item: entry.item, amount: entry.amount}));
}

function canAddAmount(amount) {
    if (!state.maxTotalItems || state.maxTotalItems <= 0) {
        return amount;
    }

    return Math.max(0, Math.min(amount, state.maxTotalItems - getTotalAmount()));
}

function setSelectedAmount(item, amount) {
    const maxAmount = Number(item.maxAmount || state.maxPerItem || 1);
    const current = state.selected[item.item]?.amount || 0;
    let nextAmount = clampAmount(amount, maxAmount);

    if (nextAmount > current) {
        nextAmount = current + canAddAmount(nextAmount - current);
    }

    if (nextAmount <= 0) {
        delete state.selected[item.item];
    } else {
        state.selected[item.item] = {
            item: item.item,
            label: item.label,
            amount: nextAmount,
            maxAmount
        };
    }

    render();
}

function addItem(item) {
    const current = state.selected[item.item]?.amount || 0;
    const amountToAdd = Number(item.defaultAmount || 1) || 1;
    setSelectedAmount(item, current + amountToAdd);
}

function createItemInfo(name, meta) {
    const info = document.createElement("div");
    const titleEl = document.createElement("div");
    const metaEl = document.createElement("div");

    info.className = "item-info";
    titleEl.className = "item-name";
    titleEl.textContent = name;
    metaEl.className = "item-meta";
    metaEl.textContent = meta;

    info.appendChild(titleEl);
    info.appendChild(metaEl);

    return info;
}

function createItemImage(src, alt) {
    const slot = document.createElement("div");

    slot.className = "item-image-slot";

    if (src) {
        const image = document.createElement("img");

        image.src = src;
        image.alt = alt || "";
        image.addEventListener("error", () => {
            image.remove();
            slot.classList.add("empty-image");
        });

        slot.appendChild(image);
    } else {
        slot.classList.add("empty-image");
    }

    return slot;
}

function renderMarket() {
    marketList.innerHTML = "";
    marketCount.textContent = `${state.items.length} ${state.items.length === 1 ? "item" : "items"}`;

    state.items.forEach((item) => {
        const row = document.createElement("div");
        const addButton = document.createElement("button");
        const maxAmount = Number(item.maxAmount || state.maxPerItem || 1);

        row.className = "item-row";
        row.addEventListener("click", () => addItem(item));
        addButton.className = "add-button";
        addButton.type = "button";
        addButton.textContent = "Add";
        addButton.addEventListener("click", (event) => {
            event.stopPropagation();
            addItem(item);
        });

        row.appendChild(createItemImage(item.image, item.label));
        row.appendChild(createItemInfo(item.label, `Max ${maxAmount}`));
        row.appendChild(addButton);
        marketList.appendChild(row);
    });
}

function renderSelected() {
    const selected = Object.values(state.selected);
    const total = getTotalAmount();

    selectedList.innerHTML = "";
    totalCount.textContent = state.maxTotalItems > 0 ? `${total} / ${state.maxTotalItems}` : `${total}`;

    if (selected.length === 0) {
        const empty = document.createElement("div");
        empty.className = "empty-state";
        empty.textContent = state.emptySelectionText;
        selectedList.appendChild(empty);
        return;
    }

    selected.forEach((entry) => {
        const sourceItem = state.items.find((item) => item.item === entry.item) || entry;
        const row = document.createElement("div");
        const quantity = document.createElement("div");
        const minus = document.createElement("button");
        const input = document.createElement("input");
        const plus = document.createElement("button");
        const remove = document.createElement("button");

        row.className = "item-row";
        quantity.className = "quantity-box";

        minus.type = "button";
        minus.textContent = "-";
        minus.addEventListener("click", () => setSelectedAmount(sourceItem, entry.amount - 1));

        input.type = "number";
        input.min = "0";
        input.max = String(entry.maxAmount);
        input.value = String(entry.amount);
        input.addEventListener("change", () => setSelectedAmount(sourceItem, input.value));

        plus.type = "button";
        plus.textContent = "+";
        plus.addEventListener("click", () => setSelectedAmount(sourceItem, entry.amount + 1));

        remove.className = "remove-button";
        remove.type = "button";
        remove.textContent = "X";
        remove.addEventListener("click", () => setSelectedAmount(sourceItem, 0));

        quantity.appendChild(minus);
        quantity.appendChild(input);
        quantity.appendChild(plus);
        quantity.appendChild(remove);

        row.appendChild(createItemInfo(entry.label, entry.item));
        row.appendChild(quantity);
        selectedList.appendChild(row);
    });
}

function renderRoutes(routes, defaultRoute) {
    routeSelect.innerHTML = "";

    routes.forEach((route) => {
        const option = document.createElement("option");
        option.value = route.value;
        option.textContent = route.label;
        routeSelect.appendChild(option);
    });

    if (defaultRoute) {
        routeSelect.value = defaultRoute;
    }
}

function render() {
    renderMarket();
    renderSelected();
}

function openUi(data) {
    state = {
        items: data.items || [],
        selected: {},
        maxTotalItems: Number(data.maxTotalItems || 0) || 0,
        maxPerItem: Number(data.maxPerItem || 1) || 1,
        emptySelectionText: data.emptySelectionText || "The chest is empty"
    };

    title.textContent = data.title || "Cargo Setup";
    subtitle.textContent = data.subtitle || "Choose a route and load the cargo chest";
    startBtn.textContent = data.startButton || "Start Cargo";
    cancelBtn.textContent = data.cancelButton || "Close";

    renderRoutes(data.routes || [], data.defaultRoute);
    render();
    app.classList.remove("hidden");
}

function closeUi() {
    app.classList.add("hidden");
}


cancelBtn.addEventListener("click", () => postNui("close"));

startBtn.addEventListener("click", () => {
    postNui("startCargo", {
        route: routeSelect.value,
        items: getSelectedArray()
    });
});

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !app.classList.contains("hidden")) {
        postNui("close");
    }
});

window.addEventListener("message", (event) => {
    const data = event.data || {};

    if (data.type === "open") {
        openUi(data);
    } else if (data.type === "close") {
        closeUi();
    }
});
