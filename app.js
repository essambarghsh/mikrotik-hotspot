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