document.addEventListener("componentLoaded", function (e) {  
    // Check if the header component is loaded  
    if (e.detail === "header") {  
        // Dropdown functionality
        const dropdownToggle = document.querySelector('.user-dropdown-toggle');  
        const dropdownContent = document.querySelector('.user-dropdown-content');  

        // Function to update aria-expanded and toggle dropdown visibility  
        function toggleDropdown() {  
            const isExpanded = dropdownToggle.getAttribute('aria-expanded') === 'true';  
            dropdownToggle.setAttribute('aria-expanded', !isExpanded);  
            dropdownContent.classList.toggle('show');  
        }  

        // Function to close the dropdown  
        function closeDropdown() {  
            dropdownToggle.setAttribute('aria-expanded', 'false');  
            dropdownContent.classList.remove('show');  
        }  

        // Toggle dropdown when the button is clicked  
        dropdownToggle.addEventListener('click', function (e) {  
            e.stopPropagation(); // Prevent click from propagating to the document  
            toggleDropdown();  
        });  

        // Close dropdown when clicking outside of it  
        document.addEventListener('click', function (e) {  
            if (!dropdownContent.contains(e.target) && !dropdownToggle.contains(e.target)) {  
                closeDropdown();  
            }  
        });  

        // Close dropdown when a link inside the dropdown is clicked  
        const dropdownLinks = dropdownContent.querySelectorAll('a');  
        dropdownLinks.forEach(function (link) {  
            link.addEventListener('click', function () {  
                closeDropdown();  
            });  
        });

        // Side Menu functionality
        const menuOpenButton = document.querySelector('.menu-open');
        const menuCloseButton = document.querySelector('.menu-close');
        const sideMenu = document.querySelector('.menu');
        const headerContent = document.querySelector('.header-content');
        
        // Create backdrop element if it doesn't exist
        let backdrop = headerContent.querySelector('.side-menu-backdrop');
        if (!backdrop) {
            backdrop = document.createElement('div');
            backdrop.classList.add('side-menu-backdrop');
            headerContent.appendChild(backdrop);
        }

        // Function to open the side menu
        function openSideMenu() {
            menuOpenButton.setAttribute('aria-expanded', 'true');
            menuCloseButton.setAttribute('aria-expanded', 'false');
            sideMenu.classList.add('show-menu');
            backdrop.classList.add('show-backdrop');
            
            // Prevent body scrolling when menu is open
            document.body.style.overflow = 'hidden';
        }

        // Function to close the side menu
        function closeSideMenu() {
            menuOpenButton.setAttribute('aria-expanded', 'false');
            menuCloseButton.setAttribute('aria-expanded', 'true');
            sideMenu.classList.remove('show-menu');
            backdrop.classList.remove('show-backdrop');
            
            // Restore body scrolling
            document.body.style.overflow = '';
        }

        // Add event listener to the open menu button
        menuOpenButton.addEventListener('click', function (e) {
            e.stopPropagation(); // Prevent click from propagating
            openSideMenu();
        });

        // Add event listener to the close menu button
        menuCloseButton.addEventListener('click', function (e) {
            e.stopPropagation(); // Prevent click from propagating
            closeSideMenu();
        });

        // Close side menu when backdrop is clicked
        backdrop.addEventListener('click', function () {
            closeSideMenu();
        });

        // Close side menu when clicking outside of it
        document.addEventListener('click', function (e) {
            if (sideMenu && !sideMenu.contains(e.target) && 
                !menuOpenButton.contains(e.target) && 
                !menuCloseButton.contains(e.target)) {
                closeSideMenu();
            }
        });

        // Close side menu when a link inside the menu is clicked
        const menuLinks = sideMenu.querySelectorAll('a');
        menuLinks.forEach(function (link) {
            link.addEventListener('click', function () {
                closeSideMenu();
            });
        });

        // Smooth Scrolling
        const links = document.querySelectorAll('a[href^="#"]');  

        // Add click event listener to each link  
        links.forEach(link => {  
            link.addEventListener('click', function(e) {  
                // Prevent default anchor behavior  
                e.preventDefault();  
    
                // Get the target element's id from href  
                const targetId = this.getAttribute('href');  
    
                // Find the target element  
                const targetElement = document.querySelector(targetId);  
    
                if (targetElement) {  
                    // Get the element's position relative to the viewport  
                    const elementPosition = targetElement.getBoundingClientRect().top;  
                    // Get the current scroll position using scrollY instead of pageYOffset  
                    const offsetPosition = elementPosition + window.scrollY - 120;  
    
                    // Perform smooth scroll  
                    window.scrollTo({  
                        top: offsetPosition,  
                        behavior: 'smooth'  
                    });  
                }  
            });  
        });
    }
});

// Function to handle input focus/blur effects on wa-link-support
function setupWaLinkSupport() {
    // Create a style element for our custom CSS rules
    const styleElement = document.createElement('style');
    styleElement.textContent = `
        .wa-link-support.hidden-wa-link {
            display: none !important;
            pointer-events: none !important;
        }
        
        input:focus ~ .wa-link-support, 
        input:focus ~ * .wa-link-support,
        input:focus ~ * ~ .wa-link-support {
            display: none !important;
            pointer-events: none !important;
        }
    `;
    document.head.appendChild(styleElement);
    
    // Setup input event listeners
    document.addEventListener('focusin', function(e) {
        if (e.target.tagName === 'INPUT') {
            const waLinks = document.querySelectorAll('.wa-link-support');
            waLinks.forEach(link => link.classList.add('hidden-wa-link'));
        }
    });
    
    document.addEventListener('focusout', function(e) {
        if (e.target.tagName === 'INPUT') {
            const waLinks = document.querySelectorAll('.wa-link-support');
            waLinks.forEach(link => link.classList.remove('hidden-wa-link'));
        }
    });
}

document.addEventListener('DOMContentLoaded', setupWaLinkSupport);

// Color Rotation System (Sequential with Page Reload Memory)
(function() {
    // Define the list of colors to rotate through
    const colors = [
        '#e12729',
        '#159ab7',
        '#ed008c',
        '#7971ea',
        '#ff8400',
        '#ff9ed7',
        '#116594',
    ];
    
    let currentColorIndex = -1; // Start with -1 to indicate no color selected yet
    const STORAGE_KEY = 'website-color-index';
    
    // Function to update the primary color
    function updatePrimaryColor(colorIndex) {
        currentColorIndex = colorIndex;
        document.documentElement.style.setProperty('--color-primary', colors[colorIndex]);
        // Save to localStorage for next page load
        localStorage.setItem(STORAGE_KEY, colorIndex.toString());
    }
    
    // Function to handle the color rotation
    function rotateColors() {
        // Get the next color index (cycle through the list)
        const nextIndex = (currentColorIndex + 1) % colors.length;
        
        // Update the color
        updatePrimaryColor(nextIndex);
    }
    
    // Initialize the color system
    function initColorSystem() {
        // Check localStorage for the last used color index
        const savedIndex = localStorage.getItem(STORAGE_KEY);
        
        if (savedIndex !== null) {
            // Use the next color in sequence
            const nextIndex = (parseInt(savedIndex) + 1) % colors.length;
            updatePrimaryColor(nextIndex);
        } else {
            // First time using the site, start with the first color
            updatePrimaryColor(0);
        }
        
        // Set up color rotation every 30 seconds
        setInterval(rotateColors, 30000);
    }
    
    // Initialize when the DOM is loaded
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initColorSystem);
    } else {
        // DOM is already loaded
        initColorSystem();
    }
})();