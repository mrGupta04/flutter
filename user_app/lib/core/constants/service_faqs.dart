/// Marketplace FAQ copy shown on home and each care vertical.
class ServiceFaqItem {
  const ServiceFaqItem(this.question, this.answer);

  final String question;
  final String answer;
}

class ServiceFaqs {
  ServiceFaqs._();

  static const home = <ServiceFaqItem>[
    ServiceFaqItem(
      'What can I book on 1mg Care?',
      'You can find verified doctors, nurses, labs, scan centres, ambulances, and blood banks. Book online consults, clinic visits, home visits, tests, and emergency transport from one app.',
    ),
    ServiceFaqItem(
      'How do I choose between online, clinic, and home visit?',
      'Use Online for video consults, Clinic visit to see a doctor at their hospital, and Home visit when a doctor or nurse should come to your address. Filters on each listing show who offers which option.',
    ),
    ServiceFaqItem(
      'Are providers verified?',
      'Listings are from providers who complete registration and verification on this platform. Always check qualification, experience, and reviews on the profile before you book.',
    ),
    ServiceFaqItem(
      'Do I need to share my location?',
      'Location helps show nearby doctors, labs, and ambulances and set a default city. You can still search any Karnataka city or district from the city picker if you skip GPS.',
    ),
    ServiceFaqItem(
      'How do payments and reports work?',
      'Consultation and diagnostic fees are shown before you confirm. Lab and scan reports are delivered in the app and email when the centre marks them ready. Keep your booking under My Bookings.',
    ),
    ServiceFaqItem(
      'What if I need help with a booking?',
      'Open the booking from My Bookings or Profile → Support to raise a ticket. For a medical emergency call local emergency services; the app is not a substitute for 108 / 112.',
    ),
  ];

  static const doctor = <ServiceFaqItem>[
    ServiceFaqItem(
      'What consultation types can I book with a doctor?',
      'Verified doctors may offer online video consult, clinic / hospital visit, or home visit. The doctor card shows which options are available before you book.',
    ),
    ServiceFaqItem(
      'How are consultation charges decided?',
      'Each doctor sets their own fee for online, clinic, and home visit. The amount is shown on the booking screen before you confirm. Offers, if any, appear on the listing.',
    ),
    ServiceFaqItem(
      'Can I consult a specialist in my city?',
      'Yes. Filter by city or district and speciality. You can search every Karnataka district and town, or leave city as All cities to browse widely.',
    ),
    ServiceFaqItem(
      'What should I keep ready for an online consult?',
      'A stable internet connection, your symptoms, current medicines, and any recent reports. Join a few minutes before the slot from Upcoming / My Bookings.',
    ),
    ServiceFaqItem(
      'How do I reschedule or cancel?',
      'Open the booking in My Bookings. Cancellation and reschedule rules depend on how close you are to the slot and the doctor’s policy shown at checkout.',
    ),
    ServiceFaqItem(
      'Are prescriptions issued after consult?',
      'Doctors may add a prescription or advice in the booking after the consult. Digital copies appear in the booking timeline when the doctor shares them.',
    ),
  ];

  static const nurse = <ServiceFaqItem>[
    ServiceFaqItem(
      'What is home nursing care, and who needs it?',
      'A verified nurse visits your home for injections, wound care, elder care, post-surgery support, or vital monitoring. It is useful when hospital-like nursing is needed at home.',
    ),
    ServiceFaqItem(
      'What services do nurses provide at home?',
      'Typical visits include injections, IV/drip support where listed, wound dressing, catheter care, elderly assistance, and post-operative care. The nurse profile lists specialisations they accept.',
    ),
    ServiceFaqItem(
      'Are nurses qualified and verified?',
      'Nurses on this platform complete registration with qualification and experience. Check the profile for speciality, gender preference, and years of experience before booking.',
    ),
    ServiceFaqItem(
      'How is the visit fee calculated?',
      'The nurse or service sets the home-visit charge. You see the amount on the booking screen, including any extra time or consumables the nurse adds before you pay.',
    ),
    ServiceFaqItem(
      'Can I request a male or female nurse?',
      'Yes. Use the gender filter on the nurse listing, then book a profile that matches. Availability still depends on who is online in your city.',
    ),
    ServiceFaqItem(
      'What if the nurse is delayed?',
      'You can track the visit from the booking when live location is shared. If there is a delay, use in-app chat or support from My Bookings.',
    ),
  ];

  static const lab = <ServiceFaqItem>[
    ServiceFaqItem(
      'Is fasting required?',
      'Some tests require fasting. Each test card shows preparation notes. Follow those instructions before home collection or a lab visit.',
    ),
    ServiceFaqItem(
      'How is home sample collection done?',
      'A phlebotomist visits the address and slot you select, collects the sample, and takes it to the lab. Home collection appears only for labs that offer it.',
    ),
    ServiceFaqItem(
      'When will reports be available?',
      'Turnaround is shown on each test, usually 24–48 hours for routine work. Reports are added to My Bookings and emailed when the lab releases them.',
    ),
    ServiceFaqItem(
      'Can I cancel or reschedule a test?',
      'Yes, from My Bookings, typically up to two hours before the slot. Late changes follow the lab’s policy shown at checkout.',
    ),
    ServiceFaqItem(
      'How do I compare lab prices?',
      'Explore labs by highest offer, tests included, and city. Open a lab to see test-wise prices, packages, and any NABL badge on the profile.',
    ),
    ServiceFaqItem(
      'Can I upload a prescription for tests?',
      'Yes. Use Upload prescription on a lab card. The lab can quote the right tests; you confirm before collection is scheduled.',
    ),
  ];

  static const scan = <ServiceFaqItem>[
    ServiceFaqItem(
      'Which scans can I book?',
      'Centres list procedures they offer such as X-ray, ultrasound, CT, MRI, and ECG. Open a centre to see names, prices, and report time.',
    ),
    ServiceFaqItem(
      'Do I need a doctor’s referral?',
      'Some scans need a referral or clinical history. If the centre requires it, you will be asked at booking. Keep a prescription handy when you visit.',
    ),
    ServiceFaqItem(
      'How should I prepare for MRI or CT?',
      'Follow the preparation notes on the scan card. MRI may need you to remove metal objects; contrast CT/MRI may need fasting or kidney tests as advised by the centre.',
    ),
    ServiceFaqItem(
      'When are scan reports ready?',
      'Each procedure shows an expected report time, often 24 hours. Reports appear in the booking and email when the centre uploads them.',
    ),
    ServiceFaqItem(
      'Can I add more than one scan?',
      'Yes. Add scans from the same centre to the cart, then proceed. Mixing centres in one cart is not allowed until you clear the previous centre.',
    ),
    ServiceFaqItem(
      'What if I need to reschedule?',
      'Change the slot from My Bookings before the appointment, subject to the centre’s cutoff. Late cancellation follows the policy shown at checkout.',
    ),
  ];

  static const ambulance = <ServiceFaqItem>[
    ServiceFaqItem(
      'When should I book an ambulance here?',
      'Use the app for BLS, ALS, ICU, or bike medic transport when you need a verified ambulance in your city. For a life-threatening emergency also call 108 / 112 immediately.',
    ),
    ServiceFaqItem(
      'What is the difference between Bike, BLS, ALS, and ICU?',
      'Bike medic is for a paramedic on two wheels in traffic. BLS is basic life support, ALS adds advanced equipment and a trained crew, and ICU is for critical patients who need intensive support in transit.',
    ),
    ServiceFaqItem(
      'How is the fare estimated?',
      'The hub shows an estimate from pickup to drop for the selected vehicle. The final amount can change with waiting time, extra kilometres, or medical consumables used on the trip.',
    ),
    ServiceFaqItem(
      'Can I add a stop or schedule later?',
      'Yes. Add a stop on the booking sheet when offered, or use schedule for a later pickup. Live trips are assigned to the nearest free vehicle of that type.',
    ),
    ServiceFaqItem(
      'How do I track the ambulance?',
      'After a driver accepts, open the trip to see live location and status. Keep the pickup pin accurate so the crew can reach you faster.',
    ),
    ServiceFaqItem(
      'What payment methods are accepted?',
      'Cash is available at drop. Offers or wallet options appear on the booking sheet when the provider enables them.',
    ),
  ];

  static const bloodBank = <ServiceFaqItem>[
    ServiceFaqItem(
      'How do I find blood in my city?',
      'Open Blood banks, choose a city or district, and filter by blood group. Listings show verified banks and available groups when the bank keeps inventory updated.',
    ),
    ServiceFaqItem(
      'Can I request a specific component?',
      'Yes. Banks may list whole blood, packed cells, platelets, or plasma. Select the component on the bank profile or order sheet when it is offered.',
    ),
    ServiceFaqItem(
      'Is blood reserved only after I order?',
      'An order notifies the bank. Actual issue follows the bank’s stock, cross-match, and hospital documentation. Always confirm with the bank for emergencies.',
    ),
    ServiceFaqItem(
      'Do I need a hospital requisition?',
      'Most banks require a doctor’s requisition and patient details before issue. Keep those documents ready when you reach the bank.',
    ),
    ServiceFaqItem(
      'Can I register as a donor?',
      'Yes. Use Donor profile from the blood bank section to share your group and city so banks or patients can reach eligible donors when needed.',
    ),
    ServiceFaqItem(
      'What if the listed group is out of stock?',
      'Inventory changes quickly. Call or WhatsApp the bank from the profile, or search nearby banks and other groups as advised by the treating doctor.',
    ),
  ];
}
