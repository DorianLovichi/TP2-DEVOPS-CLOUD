// app.js

const API_URL = "http://127.0.0.1:5000/campaigns";

const campaignForm = document.getElementById("campaignForm");
const campaignsContainer = document.getElementById("campaigns");

// Fetch and display campaigns
async function fetchCampaigns() {
  try {
    const response = await fetch(API_URL);
    const campaigns = await response.json();
    campaignsContainer.innerHTML = campaigns
      .map(
        (c) => `
            <div class="campaign">
                <h3>${c.title}</h3>
                <p>${c.description}</p>
                <p><strong>Start:</strong> ${c.start_date} | <strong>End:</strong> ${c.end_date}</p>
            </div>
        `
      )
      .join("");
  } catch (error) {
    console.error("Error fetching campaigns:", error);
  }
}

// Add new campaign
campaignForm.addEventListener("submit", async (e) => {
  e.preventDefault();

  const title = document.getElementById("title").value;
  const description = document.getElementById("description").value;
  const startDate = document.getElementById("startDate").value;
  const endDate = document.getElementById("endDate").value;

  const newCampaign = {
    title,
    description,
    start_date: startDate,
    end_date: endDate,
  };

  try {
    await fetch(API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(newCampaign),
    });

    fetchCampaigns();
    campaignForm.reset();
  } catch (error) {
    console.error("Error adding campaign:", error);
  }
});

// Initial fetch
fetchCampaigns();
