# Nginx Reverse Proxy Setup

This repository contains two scripts for setting up Nginx as a reverse proxy on Ubuntu servers. One script configures Nginx to serve as a reverse proxy without SSL, suitable for environments where SSL termination is handled elsewhere (e.g., Cloudflare). The other script includes steps for obtaining and configuring SSL certificates from Let's Encrypt, providing a secure HTTPS setup.

## Prerequisites

- A server running Ubuntu 20.04 or later.
- `sudo` or root access on your server.
- A domain name pointing to your server's IP address.

## Usage

### Without SSL

The `no_ssl_setup.sh` script configures Nginx as a reverse proxy without SSL. This setup is ideal when SSL termination is handled externally.

To use this script:
1. Clone this repository: `git clone https://github.com/qlexqndru/nginx-reverse-proxy-setup.git`
2. Navigate to the cloned directory: `cd nginx-reverse-proxy-setup`
3. Run the script: `sudo ./no_ssl_setup.sh`
4. Follow the on-screen instructions to complete the setup.

### With SSL

The `with_ssl_setup.sh` script automates the process of setting up Nginx as a reverse proxy with SSL certificates managed by Let's Encrypt. This ensures encrypted connections directly to your server.

To use this script:
1. Follow steps 1 and 2 as above.
2. Run the script: `sudo ./with_ssl_setup.sh`
3. Follow the on-screen instructions to complete the setup.

## Configuration Variables

Each script requires you to set specific variables at the top of the script file:
- `DOMAIN_NAME`: The domain name for your site.
- `BACKEND_IP`: The IP address of your backend server.
- `EMAIL_FOR_LETSENCRYPT` (Only for `with_ssl_setup.sh`): Your email for Let's Encrypt notifications.

## Contributing

Contributions are welcome! Feel free to fork this repository, make changes, and submit pull requests. If you encounter any problems or have suggestions, please open an issue.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
