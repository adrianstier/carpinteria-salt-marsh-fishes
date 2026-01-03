/**
 * Carpinteria Salt Marsh Fish Report - Enhancement Script
 * ========================================================
 * Dynamically enhances the R Markdown HTML report with:
 * - CSS styling improvements
 * - Navigation bar linking to portal and dashboard
 * - Scroll animations
 * - Accessibility improvements
 */

(function() {
    'use strict';

    // ========================================
    // INJECT CSS ENHANCEMENTS
    // ========================================
    function injectCSS() {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = 'report-enhancements.css';
        document.head.appendChild(link);
    }

    // ========================================
    // CREATE NAVIGATION BAR
    // ========================================
    function createNavBar() {
        const nav = document.createElement('nav');
        nav.className = 'csm-topnav';
        nav.setAttribute('role', 'navigation');
        nav.setAttribute('aria-label', 'Site navigation');

        nav.innerHTML = `
            <div class="csm-topnav-inner">
                <a href="portal.html" class="csm-topnav-brand">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                        <path d="M9 22V12h6v10"/>
                    </svg>
                    <span>CSM Fish Research</span>
                </a>
                <div class="csm-topnav-links">
                    <a href="portal.html" class="csm-topnav-link">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                            <path d="M9 22V12h6v10"/>
                        </svg>
                        Portal
                    </a>
                    <a href="dashboard.html" class="csm-topnav-link">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="3" y="3" width="7" height="7" rx="1"/>
                            <rect x="14" y="3" width="7" height="7" rx="1"/>
                            <rect x="3" y="14" width="7" height="7" rx="1"/>
                            <rect x="14" y="14" width="7" height="7" rx="1"/>
                        </svg>
                        Dashboard
                    </a>
                    <span class="csm-topnav-divider"></span>
                    <a href="https://portal.edirepository.org/nis/mapbrowse?packageid=edi.648.8" target="_blank" class="csm-topnav-link csm-topnav-link-external">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>
                        </svg>
                        Data (EDI)
                    </a>
                </div>
            </div>
        `;

        // Insert at the beginning of body
        document.body.insertBefore(nav, document.body.firstChild);

        // Add body padding for fixed nav
        document.body.style.paddingTop = '56px';
    }

    // ========================================
    // INJECT NAV BAR STYLES
    // ========================================
    function injectNavStyles() {
        const style = document.createElement('style');
        style.textContent = `
            .csm-topnav {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                height: 56px;
                background: linear-gradient(180deg, #1a1a1a 0%, #0d2137 100%);
                z-index: 10000;
                box-shadow: 0 2px 10px rgba(0,0,0,0.15);
            }

            .csm-topnav-inner {
                max-width: 1200px;
                margin: 0 auto;
                height: 100%;
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: 0 24px;
            }

            .csm-topnav-brand {
                display: flex;
                align-items: center;
                gap: 10px;
                color: #6baed6;
                text-decoration: none;
                font-family: 'Source Sans 3', -apple-system, sans-serif;
                font-size: 15px;
                font-weight: 600;
                transition: color 0.2s ease;
            }

            .csm-topnav-brand:hover {
                color: #c6dbef;
            }

            .csm-topnav-brand svg {
                opacity: 0.8;
            }

            .csm-topnav-links {
                display: flex;
                align-items: center;
                gap: 8px;
            }

            .csm-topnav-link {
                display: flex;
                align-items: center;
                gap: 6px;
                padding: 8px 14px;
                color: rgba(255,255,255,0.75);
                text-decoration: none;
                font-family: 'Source Sans 3', -apple-system, sans-serif;
                font-size: 13px;
                font-weight: 500;
                border-radius: 6px;
                transition: all 0.2s ease;
            }

            .csm-topnav-link:hover {
                background: rgba(255,255,255,0.1);
                color: #fff;
            }

            .csm-topnav-link svg {
                opacity: 0.7;
            }

            .csm-topnav-link:hover svg {
                opacity: 1;
            }

            .csm-topnav-link-external {
                background: rgba(33, 113, 181, 0.2);
                color: #6baed6;
            }

            .csm-topnav-link-external:hover {
                background: rgba(33, 113, 181, 0.3);
                color: #c6dbef;
            }

            .csm-topnav-divider {
                width: 1px;
                height: 24px;
                background: rgba(255,255,255,0.15);
                margin: 0 8px;
            }

            @media (max-width: 768px) {
                .csm-topnav-inner {
                    padding: 0 16px;
                }

                .csm-topnav-brand span {
                    display: none;
                }

                .csm-topnav-link span {
                    display: none;
                }

                .csm-topnav-link {
                    padding: 8px 10px;
                }

                .csm-topnav-divider {
                    display: none;
                }
            }

            /* Adjust TOC position */
            .col-xs-12.col-sm-4.col-md-3 {
                top: 56px !important;
            }

            /* Smooth scroll offset for anchor links */
            :target::before {
                content: '';
                display: block;
                height: 70px;
                margin-top: -70px;
            }
        `;
        document.head.appendChild(style);
    }

    // ========================================
    // SCROLL ANIMATION OBSERVER
    // ========================================
    function setupScrollAnimations() {
        const sections = document.querySelectorAll('.section.level1, .section.level2');

        if ('IntersectionObserver' in window) {
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('visible');
                        observer.unobserve(entry.target);
                    }
                });
            }, {
                threshold: 0.1,
                rootMargin: '0px 0px -50px 0px'
            });

            sections.forEach(section => {
                observer.observe(section);
            });
        } else {
            // Fallback for older browsers
            sections.forEach(section => {
                section.classList.add('visible');
            });
        }
    }

    // ========================================
    // ENHANCE SPECIES CARDS
    // ========================================
    function enhanceSpeciesCards() {
        // Find image containers and wrap them with species-card class
        const figures = document.querySelectorAll('.figure');
        figures.forEach(figure => {
            if (figure.querySelector('img')) {
                figure.classList.add('species-card');
            }
        });

        // Also check for direct images in certain sections
        const speciesSection = document.querySelector('#species-accounts, #key-species, #common-species');
        if (speciesSection) {
            const images = speciesSection.querySelectorAll('img');
            images.forEach(img => {
                const parent = img.closest('div');
                if (parent && !parent.classList.contains('species-card')) {
                    parent.classList.add('species-card');
                }
            });
        }
    }

    // ========================================
    // ENHANCE TABLES
    // ========================================
    function enhanceTables() {
        const tables = document.querySelectorAll('table:not(.dataTable)');
        tables.forEach(table => {
            // Add responsive wrapper
            if (!table.parentElement.classList.contains('table-responsive')) {
                const wrapper = document.createElement('div');
                wrapper.className = 'table-responsive';
                table.parentNode.insertBefore(wrapper, table);
                wrapper.appendChild(table);
            }
        });
    }

    // ========================================
    // ADD SECTION INDICES FOR STAGGERED ANIMATION
    // ========================================
    function addSectionIndices() {
        const sections = document.querySelectorAll('.section.level1');
        sections.forEach((section, index) => {
            section.style.setProperty('--section-index', index);
        });
    }

    // ========================================
    // ACCESSIBILITY IMPROVEMENTS
    // ========================================
    function improveAccessibility() {
        // Add skip link
        const skipLink = document.createElement('a');
        skipLink.href = '#main-content';
        skipLink.className = 'sr-only sr-only-focusable';
        skipLink.textContent = 'Skip to main content';
        skipLink.style.cssText = `
            position: absolute;
            top: -40px;
            left: 0;
            padding: 8px 16px;
            background: #2171b5;
            color: white;
            z-index: 100000;
            transition: top 0.3s;
        `;
        skipLink.addEventListener('focus', () => {
            skipLink.style.top = '60px';
        });
        skipLink.addEventListener('blur', () => {
            skipLink.style.top = '-40px';
        });
        document.body.insertBefore(skipLink, document.body.firstChild);

        // Add id to main content area
        const mainContent = document.querySelector('.main-container') || document.querySelector('.container-fluid');
        if (mainContent && !mainContent.id) {
            mainContent.id = 'main-content';
        }

        // Improve focus visibility
        const focusStyle = document.createElement('style');
        focusStyle.textContent = `
            .sr-only-focusable:focus {
                position: absolute !important;
                top: 60px !important;
            }
        `;
        document.head.appendChild(focusStyle);
    }

    // ========================================
    // INIT
    // ========================================
    function init() {
        // Inject CSS first
        injectCSS();
        injectNavStyles();

        // Create navigation
        createNavBar();

        // Run DOM enhancements after a short delay to ensure CSS is loaded
        requestAnimationFrame(() => {
            enhanceSpeciesCards();
            enhanceTables();
            addSectionIndices();
            improveAccessibility();

            // Setup scroll animations after everything is ready
            setTimeout(setupScrollAnimations, 100);
        });
    }

    // Run when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
