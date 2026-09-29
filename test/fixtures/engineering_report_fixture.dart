const engineeringReportFixture = {
  'title': 'Woodchipper rotor calculations',
  'summary':
      'Calculate governing cutting loads, rotor torque, and shaft deflection for the woodchipper rotor assembly, tracing each load case to allocated requirements. Verify rotor and knife-retention integrity against agreed stress, deflection, and life criteria. Confirm operating duty, geometry, and acceptance limits before numerical sizing or component decisions.',
  'sections': [
    {
      'heading': 'Required inputs',
      'columns': ['Requirement group', 'Values to allocate or confirm'],
      'rows': [
        [
          'Cutting duty',
          'To confirm: wood diameter, species and condition, feed rate, knife count, and simultaneous knife engagement.',
        ],
        [
          'Operating duty',
          'To confirm: nominal and maximum rotor speed, throughput, drive power, available torque, and continuous or peak duty.',
        ],
        [
          'Rotor geometry',
          'To confirm: cutting radius, shaft spans, bearing positions, knife-seat geometry, materials, and manufacturing tolerances.',
        ],
      ],
    },
    {
      'heading': 'Calculation sequence',
      'columns': [
        'Check',
        'Preliminary calculation',
        'Result or design decision',
      ],
      'rows': [
        [
          'Cutting load',
          'Establish peak tangential knife force from a justified cutting-load model or representative tests, accounting for wood condition and simultaneous knife engagement.',
          'Governing cutting-force load case; supporting model or test evidence required.',
        ],
        [
          'Rotor torque',
          'T = F_t × r, where T is torque in N·m, F_t is tangential force in N, and r is cutting radius in m. Sum simultaneous knife contributions for the governing load case.',
          'Peak rotor torque to compare with the drive and shaft requirements.',
        ],
        [
          'Shaft deflection',
          'Use the confirmed support spans, bearing constraints, and combined load cases to calculate shaft deflection. Confirm that the selected beam model represents the actual support arrangement.',
          'Deflection at the knife and bearing locations; allowable values to confirm.',
        ],
      ],
    },
    {
      'heading': 'Traceability and acceptance',
      'columns': [
        'Requirement or constraint',
        'Calculation evidence',
        'Acceptance criterion',
      ],
      'rows': [
        [
          'Rotor and shaft integrity',
          'Load-case register, stress and deflection calculations, and assumptions linked to allocated requirements.',
          'To confirm: allowable stress, deflection, duty cycle, fatigue life, and required design factors.',
        ],
        [
          'Knife retention',
          'Joint-load and retention assessment for the confirmed knife geometry and operating envelope.',
          'To confirm: retention requirements, joint construction, and applicable safety requirements.',
        ],
      ],
    },
  ],
};
