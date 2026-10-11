let monthlyChart = null;
let productsChart = null;

const money = (value) => {
  if (value === null || value === undefined || value === "") return "—";
  return "₹" + Number(value).toLocaleString("en-IN", { maximumFractionDigits: 2 });
};
const safe = (value) => value === null || value === undefined ? "—" : value;

function putRows(id, rows, columns, formatter = {}) {
  const tbody = document.getElementById(id);
  tbody.innerHTML = "";
  if (!rows || !rows.length) {
    tbody.innerHTML = `<tr><td colspan="${columns.length}">No rows found</td></tr>`;
    return;
  }
  rows.forEach(row => {
    const tr = document.createElement("tr");
    columns.forEach(col => {
      const td = document.createElement("td");
      const value = row[col];
      td.textContent = formatter[col] ? formatter[col](value) : safe(value);
      tr.appendChild(td);
    });
    tbody.appendChild(tr);
  });
}

function renderCharts(data) {
  if (monthlyChart) monthlyChart.destroy();
  monthlyChart = new Chart(document.getElementById("monthlyChart"), {
    type: "line",
    data: {
      labels: data.monthly.map(x => x.month_label),
      datasets: [{ label: "Revenue (₹)", data: data.monthly.map(x => Number(x.revenue)), tension: .25 }]
    },
    options: { responsive: true, plugins: { legend: { display: true } } }
  });

  if (productsChart) productsChart.destroy();
  productsChart = new Chart(document.getElementById("productsChart"), {
    type: "bar",
    data: {
      labels: data.products.map(x => x.product_name),
      datasets: [{ label: "Revenue (₹)", data: data.products.map(x => Number(x.revenue)) }]
    },
    options: { responsive: true, indexAxis: "y", plugins: { legend: { display: false } } }
  });
}

async function loadDashboard() {
  const message = document.getElementById("message");
  message.className = "message";
  message.textContent = "Loading dashboard…";
  try {
    const response = await fetch("/api/dashboard");
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Could not load dashboard.");
    document.getElementById("revenue").textContent = money(data.kpis.revenue);
    document.getElementById("orders").textContent = Number(data.kpis.orders_count).toLocaleString("en-IN");
    document.getElementById("customers").textContent = Number(data.kpis.customers_count).toLocaleString("en-IN");
    document.getElementById("average").textContent = money(data.kpis.average_order);

    putRows("monthlyRows", data.monthly,
      ["month_label","revenue","mom_growth","running_revenue","rolling_3_month_avg"],
      { revenue: money, mom_growth: v => v === null ? "—" : `${v}%`, running_revenue: money, rolling_3_month_avg: money });
    putRows("productRows", data.products,
      ["product_name","category","revenue","revenue_rank","dense_revenue_rank"], { revenue: money });
    putRows("customerRows", data.customers,
      ["customer_name","total_spend","customer_quartile"], { total_spend: money, customer_quartile: v => `Q${v}` });
    putRows("groupRows", data.grouping_rows,
      ["store_name","category","revenue","summary_level"], { revenue: money });
    putRows("summaryRows", data.materialized_summary,
      ["month_label","category","revenue"], { revenue: money });

    const inactive = document.getElementById("inactiveList");
    inactive.innerHTML = "";
    if (!data.inactive_customers.length) {
      inactive.innerHTML = "<li>All customers have placed an order.</li>";
    } else {
      data.inactive_customers.forEach(row => {
        const li = document.createElement("li");
        li.textContent = row.customer_name;
        inactive.appendChild(li);
      });
    }
    renderCharts(data);
    message.textContent = "Dashboard loaded successfully.";
  } catch (err) {
    message.className = "message error";
    message.textContent = "Could not load data. " + err.message + " Open README.md and follow the setup steps.";
  }
}

document.getElementById("refreshBtn").addEventListener("click", async () => {
  const message = document.getElementById("message");
  message.className = "message";
  message.textContent = "Refreshing summary table…";
  try {
    const response = await fetch("/api/refresh-summary", { method: "POST" });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Refresh failed.");
    message.textContent = data.message;
    await loadDashboard();
  } catch (err) {
    message.className = "message error";
    message.textContent = "Refresh failed: " + err.message;
  }
});

loadDashboard();
