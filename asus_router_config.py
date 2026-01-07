#!/usr/bin/env python3
"""
Asus Router Time-Based URL Filtering Configuration Script

This script uses Selenium to automatically configure URL filtering on an Asus router
via its WebUI. It can activate or deactivate URL filtering based on command-line arguments.

Usage:
    python asus_router_config.py activate [options]
    python asus_router_config.py deactivate [options]

Environment Variables:
    ROUTER_IP: IP address of the router (default: 192.168.0.1)
    ROUTER_USERNAME: Router admin username (default: admin)
    ROUTER_PASSWORD: Router admin password (required)
"""

import argparse
import os
import sys
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from pyvirtualdisplay import Display
from webdriver_manager.firefox import GeckoDriverManager


class AsusRouterConfigurator:
    """Handles Asus router configuration via Selenium WebDriver."""
    
    def __init__(self, router_ip, username, password, headless=True, use_https=False):
        """
        Initialize the configurator.
        
        Args:
            router_ip: Router IP address
            username: Router admin username
            password: Router admin password
            headless: Run browser in headless mode (default: True)
            use_https: Use HTTPS instead of HTTP (default: False)
        """
        self.router_ip = router_ip
        self.username = username
        self.password = password
        self.headless = headless
        self.use_https = use_https
        self.protocol = "https" if use_https else "http"
        self.driver = None
        self.wait = None
        self.display = None
        
    def setup_driver(self):
        """Set up and configure the Firefox WebDriver with virtual display for headless operation."""
        # Start virtual display for headless operation (required for Raspberry Pi)
        if self.headless:
            self.display = Display(visible=0, size=(1024, 768))
            self.display.start()
            print("Virtual display started for headless operation")
        
        firefox_options = Options()
        
        # Firefox-specific options
        firefox_options.set_preference("browser.privatebrowsing.autostart", False)
        firefox_options.set_preference("network.http.phishy-userpass-length", 255)
        firefox_options.set_preference("network.automatic-ntlm-auth.trusted-uris", self.router_ip)
        
        # Accept insecure certificates (for routers with self-signed certs)
        firefox_options.accept_insecure_certs = True
        
        # Get the geckodriver path using webdriver_manager
        # First try to use locally installed geckodriver from venv
        venv_geckodriver = os.path.join('/snap', 'bin',, 'geckodriver')
        
        if os.path.exists(venv_geckodriver):
            print(f"Using locally installed geckodriver at: {venv_geckodriver}")
            geckodriver_path = venv_geckodriver
        else:
            # Fallback to webdriver_manager to download if not found locally
            print("Locally installed geckodriver not found, using webdriver_manager to install...")
            geckodriver_path = GeckoDriverManager().install()
            print(f"Geckodriver installed via webdriver_manager at: {geckodriver_path}")
        
        # Create service with the geckodriver path
        service = Service(executable_path=geckodriver_path)
        
        # Initialize Firefox WebDriver
        self.driver = webdriver.Firefox(service=service, options=firefox_options)
        self.wait = WebDriverWait(self.driver, 20)
        
        print("Firefox WebDriver initialized successfully")
        
    def login(self):
        """Log in to the router's WebUI."""
        try:
            # Navigate to router admin page
            #url = f"{self.protocol}://{self.router_ip}"
            url = f"http://{self.router_ip}/Main_Login.asp"
            print(f"Navigating to {url}")
            self.driver.get(url)
            
            # Wait for login page to load
            time.sleep(5)
            print("Current url (should be asusrouter.com/blablabla): ",self.driver.current_url)
            # Find and fill username field
            print("Attempting to log in...")
            username_field = self.driver.find_element(By.NAME, "login_username")
            username_field.clear()
            username_field.send_keys(self.username)
            
            # Find and fill password field
            password_field = self.driver.find_element(By.NAME, "login_passwd")
            password_field.clear()
            password_field.send_keys(self.password)
            
            # Submit login form
            login_button = self.driver.find_element(By.CLASS_NAME, "button")
            login_button.click()
            
            # Wait for dashboard to load
            time.sleep(5)
            
            print("Successfully logged in to router")
            return True
            
        except TimeoutException:
            print("ERROR: Timeout while trying to log in")
            return False
        except NoSuchElementException as e:
            print(f"ERROR: Could not find login element: {e}")
            return False
        except Exception as e:
            print(f"ERROR: Unexpected error during login: {e}")
            return False
    
    def navigate_to_url_filter(self):
        """Navigate to the URL Filter configuration page."""
        try:
            # Asus routers typically have URL Filter under:
            # Advanced Settings -> Firewall -> URL Filter
            print("Navigating to URL Filter page...")
            
            # Navigate directly to the URL filter page
            # The exact URL may vary by router model, common paths:
            # - Advanced_URLFilter_Content.asp (most common)
            # - ParentalControl.asp (some models)
            # - Advanced_Firewall_Content.asp (older models)
            
            # Try the most common URL path first
            filter_url = "http://www.asusrouter.com/Advanced_URLFilter_Content.asp"
            self.driver.get(filter_url)
            
            time.sleep(5)
            print("Navigated to URL Filter page")
            print(f"Note: If this page is incorrect, the URL path may vary by router model.")
            print(f"      Check your router's admin interface for the correct path.")
            return True
            
        except Exception as e:
            print(f"ERROR: Failed to navigate to URL filter page: {e}")
            return False
    
    def set_url_filter_state(self, activate):
        """
        Enable or disable URL filtering.
        
        Args:
            activate: True to enable, False to disable
            
        Note:
            Radio elements are accessed by name attribute, where the first element
            in the list is Enable and the second is Disable.
        """
        try:
            action = "Activating" if activate else "Deactivating"
            print(f"{action} URL filtering...")
            
            # Find radio buttons by name attribute
            # The first element is Enable, the second is Disable
            radio_buttons = self.driver.find_elements(By.NAME, "url_enable_x")
            
            if len(radio_buttons) < 2:
                raise Exception(
                    f"URL filtering radio buttons not found or incomplete. "
                    f"Expected 2 radio buttons with name=\"url_enable_x\", found {len(radio_buttons)}. "
                    f"Please verify the router interface or check element selectors."
                )
            
            if activate:
                # Click the first radio button (Enable)
                radio_buttons[0].click()
            else:
                # Click the second radio button (Disable)
                radio_buttons[1].click()
            
            time.sleep(1)
            
            # Apply changes - find apply button (button is always present)
            apply_button = self.driver.find_element(By.XPATH, "//input[@value='Apply']")
            apply_button.click()
            
            time.sleep(3)
            
            state = "activated" if activate else "deactivated"
            print(f"URL filtering successfully {state}")
            return True
            
        except TimeoutException:
            print(f"ERROR: Timeout while trying to {action.lower()} URL filtering")
            print("Note: Element IDs may vary by router model. Manual configuration may be needed.")
            return False
        except NoSuchElementException as e:
            print(f"ERROR: Could not find URL filter element: {e}")
            print("Note: The router WebUI structure may differ from expected. Check element IDs.")
            return False
        except Exception as e:
            print(f"ERROR: Unexpected error while configuring URL filter: {e}")
            return False
    
    def configure(self, activate):
        """
        Main configuration method.
        
        Args:
            activate: True to activate filtering, False to deactivate
        
        Returns:
            True if successful, False otherwise
        """
        try:
            self.setup_driver()
            
            if not self.login():
                return False
            
            if not self.navigate_to_url_filter():
                return False
            
            if not self.set_url_filter_state(activate):
                return False
            
            print("Configuration completed successfully!")
            return True
            
        except Exception as e:
            print(f"ERROR: Configuration failed: {e}")
            return False
        finally:
            if self.driver:
                self.driver.quit()
                print("Browser closed")
            if self.display:
                self.display.stop()
                print("Virtual display stopped")


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Configure Asus Router URL Filtering via Selenium",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s activate
  %(prog)s deactivate
  %(prog)s activate --router-ip 192.168.0.1 --username admin
  
Environment Variables:
  ROUTER_IP        Router IP address (default: 192.168.0.1)
  ROUTER_USERNAME  Router admin username (default: admin)
  ROUTER_PASSWORD  Router admin password (required if not provided via --password)
        """
    )
    
    parser.add_argument(
        "action",
        choices=["activate", "deactivate"],
        help="Action to perform: activate or deactivate URL filtering"
    )
    
    parser.add_argument(
        "--router-ip",
        default=os.getenv("ROUTER_IP", "192.168.0.1"),
        help="Router IP address (default: 192.168.0.1 or ROUTER_IP env var)"
    )
    
    parser.add_argument(
        "--username",
        default=os.getenv("ROUTER_USERNAME", "admin"),
        help="Router admin username (default: admin or ROUTER_USERNAME env var)"
    )
    
    parser.add_argument(
        "--password",
        default=os.getenv("ROUTER_PASSWORD"),
        help="Router admin password (default: ROUTER_PASSWORD env var)"
    )
    
    parser.add_argument(
        "--headless",
        action="store_true",
        default=True,
        help="Run browser in headless mode (default: True)"
    )
    
    parser.add_argument(
        "--no-headless",
        dest="headless",
        action="store_false",
        help="Run browser with visible GUI"
    )
    
    parser.add_argument(
        "--use-https",
        action="store_true",
        default=False,
        help="Use HTTPS instead of HTTP (default: False)"
    )
    
    args = parser.parse_args()
    
    # Validate password
    if not args.password:
        print("ERROR: Router password is required!")
        print("Provide it via --password argument or ROUTER_PASSWORD environment variable")
        sys.exit(1)
    
    # Create configurator instance
    configurator = AsusRouterConfigurator(
        router_ip=args.router_ip,
        username=args.username,
        password=args.password,
        headless=args.headless,
        use_https=args.use_https
    )
    
    # Perform configuration
    activate = args.action == "activate"
    success = configurator.configure(activate)
    
    # Exit with appropriate status code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
