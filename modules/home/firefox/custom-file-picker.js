// ==UserScript==
// @name           Custom File Picker
// @namespace      http://localhost
// @description    Replace Firefox's file picker with Yazi
// @include        *
// @version        1.0
// @grant          none
// ==/UserScript==

(function () {
  "use strict";

  // Function to handle file input elements
  function handleFileInputs() {
    // Find all file input elements
    const fileInputs = document.querySelectorAll('input[type="file"]');

    fileInputs.forEach((input) => {
      // Skip if already processed
      if (input.dataset.customPicker) return;

      // Mark as processed
      input.dataset.customPicker = "true";

      // Create a custom button
      const customButton = document.createElement("button");
      customButton.textContent = "Browse with Yazi";
      customButton.style.marginLeft = "5px";
      customButton.style.padding = "2px 5px";
      customButton.style.backgroundColor = "#4a4a4a";
      customButton.style.color = "white";
      customButton.style.border = "none";
      customButton.style.borderRadius = "3px";
      customButton.style.cursor = "pointer";

      // Add click event to the custom button
      customButton.addEventListener("click", function (e) {
        e.preventDefault();
        e.stopPropagation();

        // Call our custom file picker script
        const exec = window.require("child_process").exec;
        exec("firefox-custom-file-picker", (error, stdout, stderr) => {
          if (error) {
            console.error(`Error: ${error.message}`);
            return;
          }
          if (stderr) {
            console.error(`stderr: ${stderr}`);
            return;
          }

          // The file path should be in the clipboard now
          // The user will need to paste it manually
          alert(
            "Please paste the file path from clipboard into the input field",
          );
        });
      });

      // Insert the custom button after the file input
      if (input.parentNode) {
        input.parentNode.insertBefore(customButton, input.nextSibling);
      }
    });
  }

  // Run on page load
  handleFileInputs();

  // Also run when DOM changes
  const observer = new MutationObserver(function (mutations) {
    handleFileInputs();
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });
})();
