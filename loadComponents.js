document.addEventListener("DOMContentLoaded", function () {  
    // Add base URL constant - adjust this according to your project structure  
    const BASE_URL = window.location.origin + '/';  

    function loadComponent(placeholderId, filePath, delay = 0) {  
        const placeholder = document.getElementById(placeholderId);  

        if (placeholder) {  
            fetch(`${BASE_URL}${filePath}`)  
                .then(response => {  
                    if (!response.ok) {  
                        throw new Error(`Failed to load ${filePath}`);  
                    }  
                    return response.text();  
                })  
                .then(data => {  
                    setTimeout(() => {  
                        placeholder.innerHTML = data;  
                        // Dispatch a custom event when the component is loaded  
                        const event = new CustomEvent("componentLoaded", { detail: placeholderId });  
                        document.dispatchEvent(event);  
                    }, delay); // Delay in milliseconds  
                })  
                .catch(error => {  
                    // console.error(`Error loading ${filePath}:`, error);  
                });  
        } else {  
            // console.warn(`Placeholder with ID "${placeholderId}" not found.`);  
        }  
    }  

    // Function to load and render plans    
    function loadPlans(delay = 0) {  
        const plansContainer = document.getElementById('plansContainer');  

        setTimeout(() => {  
            fetch(`${BASE_URL}plans.json`)  
                .then(response => response.json())  
                .then(data => {  
                    const plansHTML = data.plans.map(plan => `  
                        <div class="plan type-${plan.type}">  
                            <div class="plan-badge-top">  
                                <div class="plan-badge">  
                                    <span class="plan-badge-animate"></span>  
                                    <span class="relative z-10">${plan.badge}</span>  
                                </div>  
                            </div>  
                            <div class="plan-heading">${plan.heading}</div>  
                            <div class="plan-price">${plan.price}</div>  
                            <ul class="plan-features">  
                                ${plan.features.map(feature => `  
                                    <li>  
                                        <span class="plan-feature-icon">  
                                            <img src="${BASE_URL}img/icon-park-solid--check-one.png" alt="">  
                                        </span>  
                                        <span class="plan-feature-name">  
                                            <span>${feature.speed}</span>  
                                            <span>-</span>  
                                            <span>(${feature.arabicSpeed})</span>  
                                        </span>  
                                    </li>  
                                `).join('')}  
                            </ul>  
                        </div>  
                    `).join('');  

                    plansContainer.innerHTML = `  
                        <div class="plans">  
                            ${plansHTML}  
                        </div>  
                    `;      
                })  
                .catch(error => {  
                    // console.error('Error loading plans:', error);  
                });  
        }, delay);  
    }  

    function loadPOS(delay = 0) {  
        const posContainer = document.getElementById('posContainer');  

        setTimeout(() => {  
            fetch(`${BASE_URL}pos.json`)  
                .then(response => response.json())  
                .then(data => {  
                    const posHTML = data.pos.map(pos => `  
                        <div class="pos">  
                            <div class="pos-logo">  
                                <img width="64" height="64" src="${BASE_URL}img/solar--shop-bold.png" alt="${pos.name}">  
                            </div>  
                            <div class="pos-info">  
                                <span class="pos-name">${pos.name}</span>  
                                <span class="pos-address">  
                                    <span class="pos-address-icon">  
                                        <img class="w-5 h-5 animate-bounce" src="${BASE_URL}img/mdi--address-marker.png" alt="${pos.name}">  
                                    </span>  
                                    <span class="pos-address-name">${pos.address}</span>  
                                </span>  
                                <span class="pos-badges">  
                                    ${pos.badges.map(badge => `  
                                        <span class="pos-badge">${badge.service}</span>  
                                    `).join('')}  
                                </span>  
                            </div>  
                        </div>      
                    `).join('');  

                    posContainer.innerHTML = `  
                        <div class="pos-grid">  
                            ${posHTML}  
                        </div>  
                    `;  
                })  
                .catch(error => {  
                    // console.error('Error loading pos:', error);  
                });  
        }, delay);  
    }

    function loadSites(delay = 0) {  
        const sitesContainer = document.getElementById('sites');  

        setTimeout(() => {  
            fetch(`${BASE_URL}sites.json`)  
                .then(response => response.json())  
                .then(data => {  
                    const sitesHTML = data.sites.map(sites => `  
                        <li>
                            <a href="${sites.url}" target="_blank" title="${sites.name}">
                                <img src="${BASE_URL}img/sites/${sites.img_slug}" alt="${sites.name}">
                                <span class="line-clamp-1">${sites.name}</span>
                            </a>
                        </li>
                    `).join('');  

                    sitesContainer.innerHTML = `  
                        <ul class="sites">  
                            ${sitesHTML}  
                        </ul>  
                    `;  
                })  
                .catch(error => {  
                    // console.error('Error loading sites:', error);  
                });  
        }, delay);  
    }

    // Load components with absolute paths  
    loadComponent("header", "components/header.html", 400);  
    loadComponent("footer", "components/footer.html", 0);  
    loadPlans(400);  
    loadPOS(400);  
    loadSites(400);  
});  