// Auto Color Palette Changer for Mikrotik Hotspot Portal
class ColorPaletteChanger {
    constructor(options = {}) {
        this.interval = options.interval || 5000; // 5 seconds default
        this.transitionDuration = options.transitionDuration || '0.2s';
        this.currentPaletteIndex = 0;
        this.isRunning = false;
        this.timer = null;
        
        // Define your color palettes here - easily add more!
        this.palettes = [
            {
                name: 'Default Blue',
                colors: {
                    '--primary-color': '#1877F2',
                    '--primary-dark-color': '#1367d2',
                    '--primary-light-color': '#a9cbfe',
                    '--primary-extra-light-color': '#bed8ff',
                    '--body-bg-color': '#e9f2ff'
                }
            },
            {
                name: 'Emerald Green',
                colors: {
                    '--primary-color': '#10b981',
                    '--primary-dark-color': '#059669',
                    '--primary-light-color': '#a7f3d0',
                    '--primary-extra-light-color': '#c6f6d5',
                    '--body-bg-color': '#ecfdf5'
                }
            },
            {
                name: 'Purple Dream',
                colors: {
                    '--primary-color': '#8b5cf6',
                    '--primary-dark-color': '#7c3aed',
                    '--primary-light-color': '#c4b5fd',
                    '--primary-extra-light-color': '#ddd6fe',
                    '--body-bg-color': '#f5f3ff'
                }
            },
            {
                name: 'Sunset Orange',
                colors: {
                    '--primary-color': '#f97316',
                    '--primary-dark-color': '#ea580c',
                    '--primary-light-color': '#fed7aa',
                    '--primary-extra-light-color': '#ffedd5',
                    '--body-bg-color': '#fff7ed'
                }
            },
            {
                name: 'Rose Pink',
                colors: {
                    '--primary-color': '#f43f5e',
                    '--primary-dark-color': '#e11d48',
                    '--primary-light-color': '#fda4af',
                    '--primary-extra-light-color': '#fecdd3',
                    '--body-bg-color': '#fff1f2'
                }
            },
            {
                name: 'Teal Ocean',
                colors: {
                    '--primary-color': '#14b8a6',
                    '--primary-dark-color': '#0f766e',
                    '--primary-light-color': '#99f6e4',
                    '--primary-extra-light-color': '#ccfbf1',
                    '--body-bg-color': '#f0fdfa'
                }
            }
        ];
        
        this.init();
    }
    
    // Initialize smooth transitions
    init() {
        this.addTransitionStyles();
        // console.log('🎨 Color Palette Changer initialized with', this.palettes.length, 'palettes');
    }
    
    // Add CSS transitions for smooth color changes
    addTransitionStyles() {
        const style = document.createElement('style');
        style.textContent = `
            :root {
                transition: 
                    --primary-color ${this.transitionDuration} ease-in-out,
                    --primary-dark-color ${this.transitionDuration} ease-in-out,
                    --primary-light-color ${this.transitionDuration} ease-in-out,
                    --primary-extra-light-color ${this.transitionDuration} ease-in-out,
                    --body-bg-color ${this.transitionDuration} ease-in-out;
            }
            
            /* Ensure all elements using these variables transition smoothly */
            *, *::before, *::after {
                transition: 
                    background-color ${this.transitionDuration} ease-in-out,
                    border-color ${this.transitionDuration} ease-in-out,
                    color ${this.transitionDuration} ease-in-out,
                    box-shadow ${this.transitionDuration} ease-in-out;
            }
        `;
        document.head.appendChild(style);
    }
    
    // Apply a specific palette
    applyPalette(paletteIndex) {
        if (paletteIndex < 0 || paletteIndex >= this.palettes.length) {
            console.warn('Invalid palette index:', paletteIndex);
            return;
        }
        
        const palette = this.palettes[paletteIndex];
        const root = document.documentElement;
        
        // Apply each color variable
        Object.entries(palette.colors).forEach(([property, value]) => {
            root.style.setProperty(property, value);
        });
        
        // console.log('🎨 Applied palette:', palette.name);
        this.currentPaletteIndex = paletteIndex;
    }
    
    // Go to next palette
    nextPalette() {
        const nextIndex = (this.currentPaletteIndex + 1) % this.palettes.length;
        this.applyPalette(nextIndex);
    }
    
    // Start automatic cycling
    start() {
        if (this.isRunning) {
            // console.log('🎨 Palette changer is already running');
            return;
        }
        
        this.isRunning = true;
        this.timer = setInterval(() => {
            this.nextPalette();
        }, this.interval);
        
        // console.log(`🎨 Started auto palette changing (${this.interval/1000}s interval)`);
    }
    
    // Stop automatic cycling
    stop() {
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
        }
        this.isRunning = false;
        // console.log('🎨 Stopped auto palette changing');
    }
    
    // Add a new palette
    addPalette(name, colors) {
        this.palettes.push({ name, colors });
        // console.log('🎨 Added new palette:', name);
    }

    // Get current palette info
    getCurrentPalette() {
        return this.palettes[this.currentPaletteIndex];
    }
    
    // Get all available palettes
    getAllPalettes() {
        return this.palettes.map((palette, index) => ({
            index,
            name: palette.name
        }));
    }
}

// Initialize and start the color changer
const colorChanger = new ColorPaletteChanger({
    interval: 5000,        // Change every 5 seconds
    transitionDuration: '0.2s' // 0.2 second smooth transition
});

// Start the automatic cycling
colorChanger.start();

// Example: Add your own custom palette
colorChanger.addPalette('Custom Dark', {
    '--primary-color': '#374151',
    '--primary-dark-color': '#1f2937',
    '--primary-light-color': '#9ca3af',
    '--primary-extra-light-color': '#d1d5db',
    '--body-bg-color': '#f9fafb'
});

// Optional: Add control buttons (uncomment if needed)
/*
// Stop/Start controls
window.toggleColorChanger = () => {
    if (colorChanger.isRunning) {
        colorChanger.stop();
    } else {
        colorChanger.start();
    }
};

// Manual palette switching
window.switchToPalette = (index) => {
    colorChanger.applyPalette(index);
};
*/

// Make it globally accessible for debugging/manual control
window.colorChanger = colorChanger;