# ONG Connect

![ONG Connect](https://img.shields.io/badge/Platform-Web%20%26%20Mobile-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.10.3-02569B?logo=flutter)
![Flask](https://img.shields.io/badge/Flask-Python-000000?logo=flask)
![License](https://img.shields.io/badge/License-MIT-green)

**ONG Connect** is a comprehensive platform that connects Non-Governmental Organizations (NGOs) with real community needs. The platform enables NGOs to register, publish social cases, and allows donors and visitors to browse and contribute to making a positive impact.

## 📋 Table of Contents

- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Installation](#-installation)
  - [Backend Setup](#backend-setup-flask-web-application)
  - [Mobile App Setup](#mobile-app-setup-flutter)
- [Usage](#-usage)
- [API Documentation](#-api-documentation)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

## ✨ Features

### For NGOs
- **Registration & Validation**: NGOs can register with verification documents and await admin approval
- **Case Management**: Create, edit, and manage social cases with rich media support
- **Profile Management**: Maintain organization profiles with logos and contact information
- **Analytics**: View statistics on published cases and impact metrics

### For Administrators
- **ONG Approval System**: Review and approve/reject pending NGO registrations
- **Case Moderation**: Approve or reject social cases before they go public
- **Dashboard**: Comprehensive analytics showing platform statistics
- **User Management**: Manage administrators and ONG accounts

### For Donors & Visitors
- **Browse Cases**: Explore social cases by category, location, or urgency
- **Advanced Filtering**: Filter cases by wilaya (region), moughataa (district), status, and category
- **Interactive Map**: View cases on an interactive map with geolocation
- **Multi-language Support**: Available in Arabic (العربية), French (Français), and English
- **Case Details**: View detailed information including beneficiaries, media gallery, and contact info

### General Features
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Real-time Statistics**: Live charts showing impact by sector and organization
- **Secure Authentication**: Password hashing, CSRF protection, and JWT tokens for mobile
- **Media Gallery**: Support for images and videos in case presentations
- **Pagination**: Efficient data loading with pagination support

## 🛠 Technology Stack

### Backend (Web Application)
- **Framework**: Flask (Python)
- **Database**: MySQL (PyMySQL)
- **Authentication**: Werkzeug Security (password hashing)
- **API**: RESTful API with CORS support
- **ORM**: Direct SQL queries with PyMySQL

### Frontend (Web)
- **Templating**: Jinja2
- **Styling**: CSS with RTL support for Arabic
- **JavaScript**: Vanilla JS for interactivity
- **Charts**: Chart visualization libraries

### Mobile Application
- **Framework**: Flutter 3.10.3
- **Language**: Dart
- **State Management**: Built-in Flutter state management
- **HTTP Client**: http package
- **Key Dependencies**:
  - `flutter_map` & `latlong2` - Interactive maps
  - `cached_network_image` - Image caching
  - `fl_chart` - Statistics visualization
  - `shimmer` - Loading animations
  - `photo_view` - Image viewing
  - `google_fonts` - Typography
  - `flutter_localizations` - Multi-language support
  - `share_plus` - Share functionality
  - `url_launcher` - Call and email integration

## 📁 Project Structure

```
Ong-Connect/
├── OngWeb/                    # Backend Flask application
│   ├── static/                # Static files (CSS, JS, uploads)
│   │   └── uploads/          # User uploads (media, logos, docs)
│   ├── templates/             # Jinja2 HTML templates
│   ├── app.py                 # Main Flask application
│   ├── config.py              # Configuration settings
│   ├── locations_data.py      # Mauritania location data
│   └── requirements.txt       # Python dependencies (if exists)
│
├── OngMobile/                 # Flutter mobile application
│   ├── lib/
│   │   ├── core/             # Core utilities and constants
│   │   │   ├── constants/    # API constants
│   │   │   └── theme/        # App theming
│   │   ├── data/             # Data layer
│   │   │   ├── models/       # Data models
│   │   │   └── services/     # API and auth services
│   │   ├── l10n/             # Localization files
│   │   ├── presentation/     # UI layer
│   │   │   ├── screens/      # App screens
│   │   │   └── widgets/      # Reusable widgets
│   │   └── main.dart         # App entry point
│   ├── android/              # Android-specific files
│   ├── ios/                  # iOS-specific files
│   ├── pubspec.yaml          # Flutter dependencies
│   └── l10n.yaml             # Localization configuration
│
├── .gitignore                # Git ignore file
└── README.md                 # This file
```

## 🚀 Installation

### Prerequisites
- **Backend**: Python 3.7+, MySQL
- **Mobile**: Flutter SDK 3.10.3+, Android Studio/Xcode

### Backend Setup (Flask Web Application)

1. **Clone the repository**
   ```bash
   git clone https://github.com/sidimohamed31/Ong-Connect.git
   cd Ong-Connect/OngWeb
   ```

2. **Create a virtual environment**
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment**
   - Windows:
     ```bash
     venv\Scripts\activate
     ```
   - macOS/Linux:
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies**
   ```bash
   pip install flask pymysql flask-cors werkzeug
   ```

5. **Configure database**
   - Create a MySQL database named `ong_connecte`
   - Update `config.py` with your database credentials:
     ```python
     DB_HOST = 'localhost'
     DB_USER = 'your_username'
     DB_PASSWORD = 'your_password'
     DB_NAME = 'ong_connecte'
     ```

6. **Initialize database**
   ```bash
   python -c "from app import init_db; init_db()"
   ```

7. **Create default admin (optional)**
   - Visit: `http://localhost:5000/create_default_admin`
   - Default credentials: `admin@ongconnect.com` / `admin123`

8. **Run the application**
   ```bash
   python app.py
   ```
   The web application will be available at `http://localhost:5000`

### Mobile App Setup (Flutter)

1. **Navigate to mobile directory**
   ```bash
   cd ../OngMobile
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API endpoint**
   - Open `lib/core/constants/api_constants.dart`
   - Update the base URL to your backend server:
     ```dart
     static const String baseUrl = 'http://your-server-ip:5000';
     ```

4. **Run the app**
   - For Android:
     ```bash
     flutter run
     ```
   - For iOS:
     ```bash
     flutter run -d ios
     ```
   - For specific device:
     ```bash
     flutter devices  # List available devices
     flutter run -d <device-id>
     ```

## 📱 Usage

### For NGOs

1. **Register**
   - Launch the mobile app or visit the web portal
   - Click "Register Now" and fill in your organization details
   - Upload verification documents
   - Wait for admin approval

2. **Login & Manage Cases**
   - Login with your approved credentials
   - Navigate to "My Cases" to view existing cases
   - Click "Add Case" to create a new social case
   - Fill in case details, select category, and add media
   - Submit for admin approval

3. **Track Impact**
   - View statistics on your profile page
   - Monitor case status (In Progress, Urgent, Resolved)

### For Administrators

1. **Login**
   - Access the admin portal at `/admin_login`
   - Use your admin credentials

2. **Approve Organizations**
   - Navigate to "Pending ONGs"
   - Review verification documents
   - Approve or reject registrations

3. **Moderate Cases**
   - Go to "Pending Cases"
   - Review case details and media
   - Approve for public visibility or reject

### For Donors/Visitors

1. **Browse Cases** (No login required)
   - Open the mobile app or visit the public dashboard
   - Browse latest social cases
   - Use filters to find specific cases by:
     - Category (Health, Education, Housing, Food, Water)
     - Location (Wilaya & Moughataa)
     - Status (In Progress, Urgent, Resolved)
     - NGO

2. **View Details**
   - Tap on any case card to see full details
   - View beneficiary information
   - Browse media gallery
   - Contact the ONG directly via call or email

3. **View on Map**
   - Navigate to Map screen
   - See all cases with geolocation markers
   - Tap markers for quick case info

## 🔌 API Documentation

The backend provides RESTful API endpoints for mobile app integration:

### Authentication
- `POST /api/auth/login` - Login (ONG or Admin)
- `POST /api/auth/register` - Register new ONG

### Social Cases
- `GET /api/cases` - Get all approved cases (with pagination & filters)
- `GET /api/cases/<id>` - Get case details
- `POST /api/cases` - Create new case (ONG only)
- `PUT /api/cases/<id>` - Update case (ONG only)
- `DELETE /api/cases/<id>` - Delete case (ONG only)

### Categories
- `GET /api/categories` - Get all categories

### Statistics
- `GET /api/stats` - Get platform statistics
- `GET /api/stats/ong/<id>` - Get ONG-specific statistics

### Admin Operations
- `GET /api/admin/pending-cases` - Get cases awaiting approval
- `GET /api/admin/pending-ongs` - Get ONGs awaiting validation
- `POST /api/admin/approve-case/<id>` - Approve a case
- `POST /api/admin/reject-case/<id>` - Reject a case
- `POST /api/admin/approve-ong/<id>` - Approve an ONG
- `POST /api/admin/reject-ong/<id>` - Reject an ONG

All API responses are in JSON format with proper UTF-8 encoding for multi-language support.

## 📸 Screenshots

*Add screenshots of your application here to showcase the UI/UX*

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow PEP 8 for Python code
- Use Flutter/Dart best practices
- Write descriptive commit messages
- Test your changes thoroughly
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Contact

**Project Repository**: [https://github.com/sidimohamed31/Ong-Connect](https://github.com/sidimohamed31/Ong-Connect)

**Email**: ongconnecte@gmail.com

## 🙏 Acknowledgments

- Thanks to all NGOs using this platform to make a difference
- Community contributors and testers
- Open-source package maintainers

---

**Made with ❤️ for a better world - Together for positive change**
