document.addEventListener("DOMContentLoaded", () => {
  const wrapper = document.getElementById("my-tools-dropdown");
  if (!wrapper) return;

  const menu = wrapper.querySelector(".custom-dropdown-menu");

  // Toggle on click
  wrapper.addEventListener("click", (e) => {
    e.stopPropagation();
    menu.classList.toggle("hidden");
  });

  // Close when clicking outside
  document.addEventListener("click", (e) => {
    if (!menu.classList.contains("hidden") && !wrapper.contains(e.target)) {
      menu.classList.add("hidden");
    }
  });

  // --- 2. Dovetail Link Construction ---
  const dovetailLinks = document.querySelectorAll(".js-dovetail-link");

  dovetailLinks.forEach((link) => {
    // Get the variables passed from the template/env
    const toolBase = link.getAttribute("data-dovetail-base");
    const owner = link.getAttribute("data-owner");
    const repo = link.getAttribute("data-repo");
    const branch = link.getAttribute("data-branch");

    // Get the current Gitea location (e.g., http://localhost:3000 or https://git.example.com)
    const currentOrigin = window.location.origin;

    // Construct the Zip URL: http://localhost:3000/Owner/Repo/archive/Branch.zip
    const zipUrl = encodeURIComponent(
      `${currentOrigin}/${owner}/${repo}/archive/${branch}.zip`
    );

    // Construct the Final URL: $DOVETAIL_WEB/scaffold?url=...
    // We use encodeURIComponent to ensure special characters in the URL don't break the query param
    link.href = `${toolBase}${zipUrl}`;
  });
});
