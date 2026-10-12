document.addEventListener("DOMContentLoaded", () => {
    const toggle = document.getElementById("sidebarToggle");
    const sidebar = document.querySelector(".sidebar");
    if (toggle && sidebar) {
        toggle.addEventListener("click", () => sidebar.classList.toggle("open"));
    }

    document.querySelectorAll("[data-confirm]").forEach((form) => {
        form.addEventListener("submit", (event) => {
            if (!window.confirm(form.dataset.confirm)) {
                event.preventDefault();
            }
        });
    });

    document.querySelectorAll(".data-panel").forEach((panel) => {
        const table = panel.querySelector(".data-table");
        if (!table) return;

        const search = document.querySelector("[data-table-search]");
        const rows = Array.from(table.querySelectorAll("tbody tr"));
        const count = panel.querySelector("[data-table-count]");
        const prev = panel.querySelector("[data-page-prev]");
        const next = panel.querySelector("[data-page-next]");
        const pageSize = 10;
        let page = 0;
        let filtered = rows;

        function render() {
            rows.forEach((row) => row.classList.add("d-none"));
            const start = page * pageSize;
            filtered.slice(start, start + pageSize).forEach((row) => row.classList.remove("d-none"));
            if (count) {
                const from = filtered.length ? start + 1 : 0;
                const to = Math.min(start + pageSize, filtered.length);
                count.textContent = `${from}-${to} of ${filtered.length}`;
            }
            if (prev) prev.disabled = page === 0;
            if (next) next.disabled = start + pageSize >= filtered.length;
        }

        if (search) {
            search.addEventListener("input", () => {
                const term = search.value.toLowerCase();
                filtered = rows.filter((row) => row.innerText.toLowerCase().includes(term));
                page = 0;
                render();
            });
        }

        if (prev) {
            prev.addEventListener("click", () => {
                page = Math.max(0, page - 1);
                render();
            });
        }

        if (next) {
            next.addEventListener("click", () => {
                if ((page + 1) * pageSize < filtered.length) page += 1;
                render();
            });
        }

        render();
    });
});
