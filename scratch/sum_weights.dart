void main() {
  final Map<String, List<double>> drlSubStepWeights = {
    'Requirements': [1.67, 1.67, 1.67, 1.67, 1.67, 1.67, 1.67, 1.67, 0.00, 1.64],
    'Concept': [1.33, 0.00, 0.00, 0.00, 1.33, 1.33, 1.33, 1.33, 1.35, 0.00],
    'Preliminary Design': [1.71, 0.00, 1.71, 0.00, 1.71, 1.71, 1.71, 0.00, 1.71, 0.00, 1.74, 0.00],
    'Detailed Design': [0.00, 0.00, 2.57, 2.57, 2.57, 0.00, 2.57, 2.57, 0.00, 2.57, 0.00, 2.58, 0.00],
    'Simulation (FEA,CFD...)': [1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.00, 0.00, 1.00, 0.00],
    'Prototype': [1.11, 1.11, 1.11, 1.11, 1.11, 1.11, 1.11, 1.11, 0.00, 1.12, 0.00],
    'Testing Validation': [2.40, 2.40, 2.40, 2.40, 0.00, 2.40],
    'Manufacturing Readiness': [1.11, 1.11, 1.11, 1.11, 1.11, 1.11, 1.11, 0.00, 1.11, 1.12, 0.00],
    'Final Release': [0.00, 1.40, 0.00, 0.00, 1.40, 1.40, 0.00, 1.40, 1.40, 0.00],
    'Continuous Improvement': [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
  };

  double total = 0.0;
  for (var key in drlSubStepWeights.keys) {
    double stageSum = 0.0;
    for (var val in drlSubStepWeights[key]!) {
      total += val;
      stageSum += val;
    }
    print('$key sum: $stageSum');
  }
  print('Total sum: $total');
}
