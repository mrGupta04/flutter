/// How patients can consult with a doctor.
enum ConsultationType {
  onlineConsult,
  bookHome,
  visitSite,
}

extension ConsultationTypeX on ConsultationType {
  String get label {
    switch (this) {
      case ConsultationType.onlineConsult:
        return 'Online Consult';
      case ConsultationType.bookHome:
        return 'Home visit';
      case ConsultationType.visitSite:
        return 'Clinic visit';
    }
  }

  String get shortLabel {
    switch (this) {
      case ConsultationType.onlineConsult:
        return 'Online';
      case ConsultationType.bookHome:
        return 'Home';
      case ConsultationType.visitSite:
        return 'Clinic';
    }
  }

  /// Query parameter value for GET /doctor/verified
  String get apiValue {
    switch (this) {
      case ConsultationType.onlineConsult:
        return 'online_consult';
      case ConsultationType.bookHome:
        return 'book_home';
      case ConsultationType.visitSite:
        return 'visit_site';
    }
  }

  static ConsultationType? fromApiValue(String? value) {
    switch (value) {
      case 'online_consult':
        return ConsultationType.onlineConsult;
      case 'book_home':
        return ConsultationType.bookHome;
      case 'visit_site':
        return ConsultationType.visitSite;
      default:
        return null;
    }
  }
}

/// Patient-facing layout options for the client demo.
enum DoctorListingDisplayMode {
  /// Three cards — tap a card to show doctors for that option only.
  selectionCards,

  /// Same three buttons on each card; unavailable options are faded.
  fadedButtons,

  /// Filter chips above the doctor list.
  filterBar,
}
