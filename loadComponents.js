// loadComponents.js  
document.addEventListener("DOMContentLoaded", function () {  
    // Function to load a component into a placeholder  
    function loadComponent(placeholderId, filePath) {  
        const placeholder = document.getElementById(placeholderId);  

        if (placeholder) {  
            fetch(filePath)  
                .then(response => {  
                    if (!response.ok) {  
                        throw new Error(`Failed to load ${filePath}`);  
                    }  
                    return response.text();  
                })  
                .then(data => {  
                    placeholder.innerHTML = data;  
                })  
                .catch(error => {  
                    console.error(`Error loading ${filePath}:`, error);  
                });  
        } else {  
            console.warn(`Placeholder with ID "${placeholderId}" not found.`);  
        }  
    }  

    // Load components  
    loadComponent("header", "header.html");  
    loadComponent("footer", "footer.html");  
});  