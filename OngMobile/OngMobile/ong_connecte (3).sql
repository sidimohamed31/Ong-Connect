-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1:3306
-- Généré le : jeu. 15 jan. 2026 à 00:16
-- Version du serveur : 8.0.44
-- Version de PHP : 8.3.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `ong_connecte`
--

-- --------------------------------------------------------

--
-- Structure de la table `administrateur`
--

DROP TABLE IF EXISTS `administrateur`;
CREATE TABLE IF NOT EXISTS `administrateur` (
  `id_admin` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mot_de_passe` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `must_change_password` tinyint(1) DEFAULT '0',
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id_admin`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_administrateur_user` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `administrateur`
--

INSERT INTO `administrateur` (`id_admin`, `nom`, `email`, `mot_de_passe`, `must_change_password`, `user_id`) VALUES
(4, 'mohamed yassin', '24612@isms.esp.mr', 'scrypt:32768:8:1$Y3U9P7NHmUhTQZ0K$a42c4d33b59c2d3a9cb85f306b41389614fe154e170a39dedf8f0215cf13d412ca4559b4ebfa8f9a0ab503bf9c6358cc7d419d376738b5af026dbc4ab202a5d4', 0, 1),
(14, 'sidi mohamed', 'sidimohamedlehbib36@gmail.com', 'scrypt:32768:8:1$eewW1XKkP7wVfekz$24272588d54f3ab217a0be0d11241ce7f29cc8205c24c873533a17f22868f875c6581bdeec93395ca5265687b923b926c1b93c8742b5051bf97039201b03a9ea', 0, 2),
(15, 'lemin', '24648@isms.esp.mr', 'scrypt:32768:8:1$xyVao9qDgrZcqyJC$8dc5bcacc45d87a7284472ddd69399dab1a76cc1e577c1f9190158655edf0ddde53dfddb1a3dfbb90fc439b8fd1ddc446d77213fe07b76a0516967cb04a83970', 0, 3),
(16, 'nourdine', '24606@isms.esp.mr', 'nourdin123', 0, 4),
(17, 'Admin', 'admin@ongconnect.com', 'scrypt:32768:8:1$6i5PrRx6QN5zlUNR$317e6820ef60561795d22887159e89440f7eed4d00167e6399a8eedfb8441cf1829734d5fb439a2c5114d21f1a784835c228876252aba478cfd98d9184a6ed7e', 0, 5);

-- --------------------------------------------------------

--
-- Structure de la table `beneficier`
--

DROP TABLE IF EXISTS `beneficier`;
CREATE TABLE IF NOT EXISTS `beneficier` (
  `id_beneficiaire` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `adresse` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description_situation` mediumtext COLLATE utf8mb4_unicode_ci,
  `id_cas_social` int DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  PRIMARY KEY (`id_beneficiaire`),
  KEY `id_cas_social` (`id_cas_social`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `beneficier`
--

INSERT INTO `beneficier` (`id_beneficiaire`, `nom`, `prenom`, `adresse`, `description_situation`, `id_cas_social`, `latitude`, `longitude`) VALUES
(2, 'Mint Samba', 'Aichatou', 'Dar Naïm, Nouakchott', 'Mère de 3 enfants, a besoin d?une aide pour frais médicaux.', 2, NULL, NULL),
(3, 'Ould Ahmed', 'Cheikh', 'Riyadh, Nouakchott', 'Étudiant ayant besoin de soutien pour la scolarité.', 3, NULL, NULL),
(4, 'Mint Ely', 'Mariem', 'Arafat, Nouakchott', 'Maison endommagée par les pluies, nécessite réparation urgente.', 1, NULL, NULL),
(7, 'med lemine ', 'med edjah', 'NDB', 'hgdywufy', 2, NULL, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `cas_social`
--

DROP TABLE IF EXISTS `cas_social`;
CREATE TABLE IF NOT EXISTS `cas_social` (
  `id_cas_social` int NOT NULL AUTO_INCREMENT,
  `titre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` mediumtext COLLATE utf8mb4_unicode_ci,
  `adresse` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_publication` date DEFAULT NULL,
  `statut` enum('En cours','Résolu','Urgent') COLLATE utf8mb4_unicode_ci DEFAULT 'En cours',
  `id_ong` int DEFAULT NULL,
  `statut_approbation` enum('en_attente','approuvé','rejeté') COLLATE utf8mb4_unicode_ci DEFAULT 'en_attente',
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `wilaya` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `moughataa` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_cas_social`),
  KEY `id_ong` (`id_ong`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `cas_social`
--

INSERT INTO `cas_social` (`id_cas_social`, `titre`, `description`, `adresse`, `date_publication`, `statut`, `id_ong`, `statut_approbation`, `latitude`, `longitude`, `wilaya`, `moughataa`) VALUES
(1, 'مساعدات غذائية عاجلة', 'الأسرة بحاجة إلى دعم غذائي فوري.', 'El Mina, Nouakchott', '2024-08-01', 'Résolu', 1, 'approuvé', NULL, NULL, NULL, NULL),
(2, 'التكاليف الطبية لطفل', 'اطلب المساعدة لدفع تكاليف الاستشارات والأدوية.', 'Dar Naïm, Nouakchott', '2024-08-05', 'En cours', 2, 'approuvé', NULL, NULL, NULL, NULL),
(3, 'دعم التعليم', 'طلب مساعدة لسداد تكاليف الأدوات المدرسية.', 'Riyadh, Nouakchott', '2024-08-10', 'Urgent', 1, 'approuvé', NULL, NULL, NULL, NULL),
(4, 'إصلاح منزل تالف', 'بيت تضرر من الأمطار الغزيرة، نحتاج مساعدات.', 'Arafat, Nouakchott', '2024-09-01', 'Urgent', 3, 'approuvé', NULL, NULL, NULL, NULL),
(6, 'دعم مريض سرطان ', 'مريض سرطان يحتاج دعم في العلاج عاجل', 'Toujounin,NKTT', '2025-12-22', 'Résolu', 1, 'approuvé', NULL, NULL, NULL, NULL),
(7, 'عائلة تحتاج إلى علاج طبي عاجل', 'عائلة مكونة من 5 أفراد تعاني من ظروف صحية صعبة. الأب يحتاج إلى عملية جراحية عاجلة ولكن لا يملك التأمين الصحي. نحتاج إلى دعمكم لتغطية تكاليف العلاج والأدوية الضرورية.', 'نواكشوط، تيارت', '2025-12-24', 'Résolu', 1, 'approuvé', NULL, NULL, NULL, NULL),
(8, 'طفل يحتاج إلى مستلزمات مدرسية', 'طفل في السنة الرابعة ابتدائي يعاني من وضعية مادية صعبة. الأسرة غير قادرة على توفير الكتب والأدوات المدرسية. نبحث عن متبرعين لمساعدته على مواصلة تعليمه بكرامة.', 'نواكشوط، الميناء', '2025-12-21', 'En cours', 1, 'approuvé', NULL, NULL, NULL, NULL),
(9, 'منزل متضرر يحتاج للترميم', 'منزل عائلة فقيرة تضرر بسبب الأمطار الأخيرة. السقف مهدد بالانهيار والجدران متصدعة. العائلة مكونة من 7 أشخاص بينهم 4 أطفال. نحتاج إلى مواد بناء ويد عاملة للترميم العاجل.', 'نواكشوط، السبخة', '2025-12-17', 'En cours', 1, 'approuvé', NULL, NULL, NULL, NULL),
(10, 'أرملة مع 4 أطفال تحتاج إلى مساعدة غذائية', 'أرملة شابة تعيل 4 أطفال صغار. لا تملك دخلاً ثابتاً وتحتاج إلى سلة غذائية شهرية لضمان تغذية أطفالها. الوضع حرج خاصة مع ارتفاع أسعار المواد الأساسية.', 'نواكشوط، عرفات', '2025-12-24', 'Urgent', 2, 'approuvé', NULL, NULL, NULL, NULL),
(11, 'مريض سكري يحتاج إلى دواء منتظم', 'رجل مسن يعاني من داء السكري المزمن. يحتاج إلى الأنسولين والأدوية بشكل يومي لكن دخله المحدود لا يسمح بذلك. نطلب دعمكم لتوفير العلاج لمدة 6 أشهر.', 'نواكشوط، توجنين', '2025-12-22', 'En cours', 2, 'approuvé', NULL, NULL, NULL, NULL),
(12, 'طالبة متفوقة تحتاج إلى رسوم جامعية', 'طالبة حاصلة على الباكالوريا بامتياز لكن عائلتها غير قادرة على دفع رسوم التسجيل الجامعي. حلمها أن تصبح طبيبة لخدمة مجتمعها. تحتاج إلى 50000 أوقية للتسجيل.', 'نواكشوط، تفرغ زينة', '2025-12-09', 'Résolu', 2, 'approuvé', NULL, NULL, NULL, NULL),
(13, 'عائلة نازحة تحتاج إلى مأوى', 'عائلة نازحة من الداخل تعيش في ظروف قاسية. يحتاجون إلى خيمة أو غرفة مؤقتة لحمايتهم من البرد والأمطار. العائلة مكونة من الوالدين و6 أطفال.', 'نواكشوط، الرياض', '2025-12-24', 'Urgent', 3, 'approuvé', NULL, NULL, NULL, NULL),
(14, 'طفل يتيم يحتاج إلى كفالة', 'طفل يتيم عمره 8 سنوات فقد والديه في حادث مروري. يعيش مع جدته المسنة التي لا تستطيع توفير احتياجاته الأساسية. نبحث عن كفيل أو متبرعين لرعايته.', 'نواكشوط، المحجرة', '2025-12-19', 'En cours', 3, 'approuvé', NULL, NULL, NULL, NULL),
(15, 'امرأة حامل تحتاج إلى رعاية صحية', 'امرأة حامل في شهرها الثامن تعاني من مضاعفات صحية. تحتاج إلى متابعة طبية دقيقة وفحوصات معملية لكن وضعها المادي لا يسمح بذلك. نطلب دعمكم لضمان ولادة آمنة.', 'نواكشوط، المينا', '2025-12-14', 'En cours', 3, 'approuvé', NULL, NULL, NULL, NULL),
(19, 'عائلة تحتاج إلى علاج طبي عاجل', 'عائلة مكونة من 5 أفراد تعاني من ظروف صحية صعبة. الأب يحتاج إلى عملية جراحية عاجلة ولكن لا يملك التأمين الصحي.', 'نواكشوط، تيارت', '2025-12-24', 'Résolu', 6, 'approuvé', NULL, NULL, NULL, NULL),
(20, 'مريض سكري يحتاج إلى دواء منتظم', 'رجل مسن يعاني من داء السكري المزمن. يحتاج إلى الأنسولين والأدوية بشكل يومي لكن دخله المحدود لا يسمح بذلك.', 'نواكشوط، توجنين', '2025-12-22', 'En cours', 2, 'approuvé', NULL, NULL, NULL, NULL),
(22, 'مريضة سرطان تحتاج إلى علاج كيميائي', 'امرأة في الأربعينات تعاني من سرطان الثدي. تحتاج إلى جلسات علاج كيميائي مكلفة. الأسرة استنفدت مدخراتها.', 'نواكشوط، كرفور', '2025-12-24', 'Urgent', 2, 'approuvé', NULL, NULL, NULL, NULL),
(23, 'طفل يحتاج إلى مستلزمات مدرسية', 'طفل يتيم في السنة الرابعة ابتدائي. الأسرة غير قادرة على توفير الكتب والأدوات المدرسية.', 'نواكشوط، الميناء', '2025-12-21', 'En cours', 9, 'approuvé', NULL, NULL, NULL, NULL),
(24, 'طالبة متفوقة تحتاج إلى رسوم جامعية', 'طالبة حاصلة على الباكالوريا بامتياز عاجزة عن دفع رسوم التسجيل الجامعي. حلمها دراسة الطب.', 'نواكشوط، تفرغ زينة', '2025-12-09', 'Résolu', 9, 'approuvé', NULL, NULL, NULL, NULL),
(25, 'مدرسة قرآنية تحتاج إلى دعم', 'مدرسة تستقبل 50 طفلاً يتيماً. تحتاج إلى ألواح، مصاحف، وسجاد للصلاة.', 'نواكشوط، الموافقية', '2025-12-04', 'Résolu', 2, 'approuvé', NULL, NULL, NULL, NULL),
(26, 'أطفال محرومون من التعليم', 'حي مهمش به 15 طفلاً خارج المدرسة. نسعى لإنشاء فصل دراسي مؤقت وتوفير معلم.', 'نواكشوط، الميناء', '2025-12-18', 'Résolu', 8, 'approuvé', NULL, NULL, NULL, NULL),
(27, 'منزل متضرر يحتاج للترميم', 'منزل عائلة فقيرة تضرر بسبب الأمطار. السقف مهدد بالانهيار والجدران متصدعة.', 'نواكشوط، السبخة', '2025-12-17', 'En cours', 2, 'approuvé', NULL, NULL, NULL, NULL),
(28, 'عائلة نازحة تحتاج إلى مأوى', 'عائلة نازحة تعيش في العراء. يحتاجون إلى خيمة أو غرفة مؤقتة لحمايتهم من البرد.', 'نواكشوط، الرياض', '2025-12-24', 'Urgent', 1, 'approuvé', NULL, NULL, NULL, NULL),
(29, 'عائلة بدون كهرباء', 'عائلة فقيرة انقطعت عنها الكهرباء منذ 3 أشهر بسبب الديون. الأطفال يدرسون على الشموع.', 'نواكشوط، دار النعيم', '2025-12-24', 'Urgent', 8, 'approuvé', NULL, NULL, NULL, NULL),
(30, 'ترميم سقف متهالك', 'منزل يأوي أيتاماً وسقفه متهالك جداً. نحتاج مواد بناء لإصلاحه قبل موسم الأمطار.', 'نواكشوط، توجنين', '2025-12-19', 'En cours', 2, 'approuvé', NULL, NULL, NULL, NULL),
(31, 'أرملة تحتاج إلى مساعدة غذائية', 'أرملة تعيل 4 أطفال ولا تملك دخلاً. تحتاج سلة غذائية شهرية (أرز، سكر، زيت).', 'نواكشوط، عرفات', '2025-12-24', 'Urgent', 8, 'approuvé', NULL, NULL, NULL, NULL),
(32, 'عائلة بدون ماء شرب', 'حي نائي لا يصله الماء. السكان يشترون الماء بأسعار غالية. نحتاج حفر بئر أو خزان.', 'نواكشوط، عرفات', '2025-12-24', 'Urgent', 8, 'approuvé', NULL, NULL, NULL, NULL),
(33, 'إفطار لأسر متعففة', 'أسرة لا تجد قوت يومها. نحتاج توفير مواد غذائية أساسية لهم.', 'نواكشوط، لكصر', '2025-12-20', 'En cours', 6, 'approuvé', NULL, NULL, NULL, NULL),
(34, 'حفر بئر لقرية', 'قرية صغيرة تعاني من العطش. حفر بئر سطحي سيوفر الماء لـ 20 عائلة.', 'الداخل', '2025-11-24', 'En cours', 9, 'approuvé', NULL, NULL, NULL, NULL),
(35, 'شاب معاق يحتاج كرسي متحرك', 'شاب أصيب بشلل ويحتاج كرسي متحرك للتنقل والذهاب للعمل.', 'نواكشوط، تيارت', '2025-12-20', 'En cours', 1, 'approuvé', NULL, NULL, NULL, NULL),
(36, 'مركز محو أمية للنساء', 'تجهيز قاعة لتعليم النساء القراءة والكتابة. نحتاج طاولات وسبورة.', 'نواكشوط، تيارت', '2025-11-29', 'Résolu', 6, 'approuvé', NULL, NULL, NULL, NULL),
(40, 'okxmlm', 'joojij', 'Nouakchott', '2025-12-29', 'En cours', 1, 'rejeté', NULL, NULL, NULL, NULL),
(41, 'Aide alimentaire urgente', 'vghgjgj', 'نواكشوط، تيارت', '2026-01-06', 'En cours', 9, 'rejeté', NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `categorie`
--

DROP TABLE IF EXISTS `categorie`;
CREATE TABLE IF NOT EXISTS `categorie` (
  `idCategorie` int NOT NULL AUTO_INCREMENT,
  `nomCategorie` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`idCategorie`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `categorie`
--

INSERT INTO `categorie` (`idCategorie`, `nomCategorie`, `description`) VALUES
(1, 'Santé', 'Cas sociaux liés aux problèmes médicaux'),
(2, 'Éducation', 'Cas liés à la scolarité ou aux études'),
(3, 'Logement', 'Aides pour réparer ou obtenir un logement'),
(4, 'Alimentation', 'Soutien alimentaire pour familles en difficulté'),
(5, 'Gaza - غزة', 'تبرعات و مساعدات لإخواننا في غزة '),
(6, 'Sudan - السودان', 'تبرعات و مساعدات لإخواننا في السودان'),
(7, 'Autre', 'Autre domaines d\'intérvation');

-- --------------------------------------------------------

--
-- Structure de la table `media`
--

DROP TABLE IF EXISTS `media`;
CREATE TABLE IF NOT EXISTS `media` (
  `id_media` int NOT NULL AUTO_INCREMENT,
  `id_cas_social` int DEFAULT NULL,
  `file_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description_media` mediumtext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id_media`),
  KEY `id_cas_social` (`id_cas_social`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `media`
--

INSERT INTO `media` (`id_media`, `id_cas_social`, `file_url`, `description_media`) VALUES
(11, 1, 'uploads/media/20251212195444_Aide-alimentaire.jpg', 'Media for case 1'),
(12, 2, 'uploads/media/20251212202156_thumbs_b_c_7ee63613170ad5cf6c8bc943b7cccebf.jpg', 'Media for case 2'),
(13, 3, 'uploads/media/20251212202539_66fe40d6b359c450e3980317_11.png', 'Media for case 3'),
(14, 4, 'uploads/media/20251212203012_--390x220.jpg', 'Media for case 4'),
(15, 6, 'uploads/media/20251222145716_-.png', 'Media for case 6'),
(16, 7, 'uploads/media/20251224231038_ffc335455bbc285645f706d58cb5e1e4.jpg', 'Media for case 7'),
(17, 28, 'uploads/media/20251224231151_1000067845-1754902355.webp', 'Media for case 28'),
(18, 8, 'uploads/media/20251224231315_school-supplies-1-AR23082020.jpg', 'Media for case 8'),
(19, 35, 'uploads/media/20251224231417_e2339a2b-211b-48da-8756-aac369057758_16x9_1200x676.webp', 'Media for case 35'),
(20, 9, 'uploads/media/20251224231544_images_1.jpg', 'Media for case 9'),
(21, 19, 'uploads/media/20251224231820_ffc335455bbc285645f706d58cb5e1e4.jpg', 'Media for case 19'),
(22, 33, 'uploads/media/20251224231955_images_2.jpg', 'Media for case 33'),
(23, 36, 'uploads/media/20251224232059_8d20768d-95dc-4c4f-aab3-51b99dab3b4c.webp', 'Media for case 36'),
(24, 13, 'uploads/media/20251224232324_1000067845-1754902355.webp', 'Media for case 13'),
(25, 14, 'uploads/media/20251224232435_images_3.jpg', 'Media for case 14'),
(26, 15, 'uploads/media/20251224232555_image1170x530cropped.jpg', 'Media for case 15'),
(30, 40, 'uploads/media/20251229101713_images_3.jpg', 'Media for case 40'),
(31, 41, 'uploads/media/20260106141729_8d20768d-95dc-4c4f-aab3-51b99dab3b4c.webp', 'Media for case 41');

-- --------------------------------------------------------

--
-- Structure de la table `ong`
--

DROP TABLE IF EXISTS `ong`;
CREATE TABLE IF NOT EXISTS `ong` (
  `id_ong` int NOT NULL AUTO_INCREMENT,
  `nom_ong` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `adresse` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telephone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `domaine_intervation` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut_de_validation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `update_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `logo_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mot_de_passe` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `verification_doc_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `must_change_password` tinyint(1) DEFAULT '0',
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id_ong`),
  KEY `fk_ong_user` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `ong`
--

INSERT INTO `ong` (`id_ong`, `nom_ong`, `adresse`, `telephone`, `email`, `domaine_intervation`, `statut_de_validation`, `update_at`, `logo_url`, `mot_de_passe`, `verification_doc_url`, `must_change_password`, `user_id`) VALUES
(1, 'إيثار', 'Nouakchott', '22334455', 'contact@solidaritemr.org', 'Santé,Éducation', 'validé', '2025-12-02 14:38:31', 'uploads/logos/logo_20251218101757_images_2.png', 'scrypt:32768:8:1$1Fk605becJABVmnQ$9502ecfe2434013a189547315a3ae4f669c299f6291842569adc0107b2ca5b0852c73f823d18d78065001d70835c008aeaf965677090cf1120d2b476f096945e', NULL, 0, 6),
(2, 'Avenir Pour Tous', 'Assaba', '22445566', 'info@avenir.org', 'Logement', 'validé', '2025-12-02 14:38:31', NULL, 'scrypt:32768:8:1$ZbMr0cVRwV5UxAIi$18c8ed208ddbd119569013e07078d12a7355b60fe75c018271b6bce29d8f68e3c1095b97e7e2b21d84b559d518fdbdd7ac956afd3588f5e37651172834bffd96', NULL, 0, 7),
(3, 'Hope Initiative', 'Trarza', '22778899', 'hello@hope.org', 'Logement', 'validé', '2025-12-02 14:38:31', NULL, 'scrypt:32768:8:1$TQBYyMgTMiMaR8YD$ffb8c5291f759d987c76e43acc0fb3cbb5fc01cd63cdd8e3a4285a1717f5c202da508ff70a6445bd9ccb98f7ba472618d72c9954829aa30284d9f83836d4946b', NULL, 0, 8),
(6, 'هلمان المؤازرة', 'ain talh', '38111269', 'med.fashion2017@gmail.com', 'Gaza - غزة,Sudan - السودان,Autre', 'validé', '2025-12-10 23:58:31', 'uploads/logos/logo_20251212114007_2025-11-23_150508.png', 'scrypt:32768:8:1$5xgKzdEv17lk5kBc$4ec7d1ca2450ca70834916b21e8a5de5d5503318d27548abbfb11bd3d8d654cf4b124e2ab5952a732887c186b7c93f2d55d9230de639183b915b398eae20b48b', NULL, 0, 9),
(8, 'قلوب محسنة', 'tevragh zeina', '22445566', 'kouloub@gmail.com', 'Alimentation', 'validé', '2025-12-12 00:45:35', 'uploads/logos/logo_20251212211108_images.jpg', 'scrypt:32768:8:1$K6qn8Q9k0PujDmnB$cdda6c73771abaaf4e169dbdf4d581c31f0d82cb87e9946941d83a944498702b62979314a6c41fe1c84747fb08f6b18af019f490f393f5dc5797cb747e7c5701', NULL, 0, 10),
(9, 'نسائم الخير', 'tevragh zeina', '30645780', 'Nesayim1@gmail.com', 'Santé,Logement,Alimentation', 'validé', '2025-12-13 16:06:52', 'uploads/logos/logo_20251213150652_images_1.png', 'scrypt:32768:8:1$YjKPDQ7bVSBMPAYw$0cd5d510551a3de55e7b3f5cb2d27540b926828fdc7675e04c2655236eb3ed09f2a441a6919b11233b6236eb865f973991e6797d2b38de2858a24857f36d9a3b', NULL, 0, 11);

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','ong') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `must_change_password` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `email`, `password_hash`, `role`, `created_at`, `must_change_password`) VALUES
(1, '24612@isms.esp.mr', 'scrypt:32768:8:1$Y3U9P7NHmUhTQZ0K$a42c4d33b59c2d3a9cb85f306b41389614fe154e170a39dedf8f0215cf13d412ca4559b4ebfa8f9a0ab503bf9c6358cc7d419d376738b5af026dbc4ab202a5d4', 'admin', '2026-01-10 17:47:54', 0),
(2, 'sidimohamedlehbib36@gmail.com', 'scrypt:32768:8:1$eewW1XKkP7wVfekz$24272588d54f3ab217a0be0d11241ce7f29cc8205c24c873533a17f22868f875c6581bdeec93395ca5265687b923b926c1b93c8742b5051bf97039201b03a9ea', 'admin', '2026-01-10 17:47:54', 0),
(3, '24648@isms.esp.mr', 'scrypt:32768:8:1$xyVao9qDgrZcqyJC$8dc5bcacc45d87a7284472ddd69399dab1a76cc1e577c1f9190158655edf0ddde53dfddb1a3dfbb90fc439b8fd1ddc446d77213fe07b76a0516967cb04a83970', 'admin', '2026-01-10 17:47:54', 0),
(4, '24606@isms.esp.mr', 'nourdin123', 'admin', '2026-01-10 17:47:54', 0),
(5, 'admin@ongconnect.com', 'scrypt:32768:8:1$6i5PrRx6QN5zlUNR$317e6820ef60561795d22887159e89440f7eed4d00167e6399a8eedfb8441cf1829734d5fb439a2c5114d21f1a784835c228876252aba478cfd98d9184a6ed7e', 'admin', '2026-01-10 17:47:54', 0),
(6, 'contact@solidaritemr.org', 'scrypt:32768:8:1$1Fk605becJABVmnQ$9502ecfe2434013a189547315a3ae4f669c299f6291842569adc0107b2ca5b0852c73f823d18d78065001d70835c008aeaf965677090cf1120d2b476f096945e', 'ong', '2026-01-10 17:47:54', 0),
(7, 'info@avenir.org', 'scrypt:32768:8:1$ZbMr0cVRwV5UxAIi$18c8ed208ddbd119569013e07078d12a7355b60fe75c018271b6bce29d8f68e3c1095b97e7e2b21d84b559d518fdbdd7ac956afd3588f5e37651172834bffd96', 'ong', '2026-01-10 17:47:54', 0),
(8, 'hello@hope.org', 'scrypt:32768:8:1$TQBYyMgTMiMaR8YD$ffb8c5291f759d987c76e43acc0fb3cbb5fc01cd63cdd8e3a4285a1717f5c202da508ff70a6445bd9ccb98f7ba472618d72c9954829aa30284d9f83836d4946b', 'ong', '2026-01-10 17:47:54', 0),
(9, 'med.fashion2017@gmail.com', 'scrypt:32768:8:1$5xgKzdEv17lk5kBc$4ec7d1ca2450ca70834916b21e8a5de5d5503318d27548abbfb11bd3d8d654cf4b124e2ab5952a732887c186b7c93f2d55d9230de639183b915b398eae20b48b', 'ong', '2026-01-10 17:47:54', 0),
(10, 'kouloub@gmail.com', 'scrypt:32768:8:1$K6qn8Q9k0PujDmnB$cdda6c73771abaaf4e169dbdf4d581c31f0d82cb87e9946941d83a944498702b62979314a6c41fe1c84747fb08f6b18af019f490f393f5dc5797cb747e7c5701', 'ong', '2026-01-10 17:47:54', 0),
(11, 'Nesayim1@gmail.com', 'scrypt:32768:8:1$YjKPDQ7bVSBMPAYw$0cd5d510551a3de55e7b3f5cb2d27540b926828fdc7675e04c2655236eb3ed09f2a441a6919b11233b6236eb865f973991e6797d2b38de2858a24857f36d9a3b', 'ong', '2026-01-10 17:47:54', 0),
(12, 'lminnmed@gmail.com', 'scrypt:32768:8:1$8LBLhaIUDnsEyxI6$c4c437ab3b76c7f62c950b59d3a167ea2b151f3dc57d15b677f4aa60ada2e6b86bf970d2d49e7a9964b9d722507ebcf35cad90278eba6a48618efae2f19e5012', 'ong', '2026-01-10 17:47:54', 0),
(13, 'medleminmed@gmail.com', 'scrypt:32768:8:1$P7faVyQdSjuWjFxM$11eb2648ea895bdca7f999feec6a2c1fe10e29ad5f32fdd8f114dc34e2c9162db56fee00847e2de8d5c9fd8f9c5e5310ecddb0fd20272761c3adfc422bc62a4f', 'ong', '2026-01-10 17:47:54', 0),
(14, 'test_debug_ong@test.com', 'scrypt:32768:8:1$DPSJ8L7KjCVH149p$4f46448aebfd7022e07957b6fb3d6646288d68575bbf84bfeb388cf89ca1099028cb1688ece9149966fc1a71c54f1aea17554b9deff7fe90537e9b0ad6a53fa2', 'ong', '2026-01-10 17:47:54', 0),
(15, 'test_fix_verification@test.com', 'scrypt:32768:8:1$x3Ae59BKkLqMcCTi$e5fde0cbddd4a73749111b0a8f29ecea803d2a80688c4c4bb152cdb19556d696dfb87f5c68accbef992c774cced5c4f33807dd9435c9bfb174f9d0ef335875bc', 'ong', '2026-01-10 17:47:54', 0),
(16, 'elvetate@gmail.com', 'scrypt:32768:8:1$WQnnTarsZHe5BaKY$6e5f873c74805afaf7f7f69e4e47a130a8b056e1dbbdc5c12e420171c9725e3d32eee4552db12164ee2ee6dcd6911ac9bc3c851cc7df265d43eb57380f4416dd', 'ong', '2026-01-10 17:47:54', 0),
(17, 'testfix8n89aq@example.com', 'scrypt:32768:8:1$tX0Hcwrm1DKFwkAA$3340ac6cea1ff96210ed7c16bcd89616dbcb99b9e42fd352b841fe2651480594f250982e1b270c1379fe76661468c4012a389e86c0f4414425029cfdd7f79ada', 'ong', '2026-01-10 17:47:54', 0);

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `administrateur`
--
ALTER TABLE `administrateur`
  ADD CONSTRAINT `fk_administrateur_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `beneficier`
--
ALTER TABLE `beneficier`
  ADD CONSTRAINT `beneficier_ibfk_1` FOREIGN KEY (`id_cas_social`) REFERENCES `cas_social` (`id_cas_social`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `cas_social`
--
ALTER TABLE `cas_social`
  ADD CONSTRAINT `cas_social_ibfk_1` FOREIGN KEY (`id_ong`) REFERENCES `ong` (`id_ong`);

--
-- Contraintes pour la table `media`
--
ALTER TABLE `media`
  ADD CONSTRAINT `media_ibfk_1` FOREIGN KEY (`id_cas_social`) REFERENCES `cas_social` (`id_cas_social`);

--
-- Contraintes pour la table `ong`
--
ALTER TABLE `ong`
  ADD CONSTRAINT `fk_ong_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
