// Label positions (fractions of each image), measured against the blueprint images.
part of 'garment_blueprints.dart';

final List<BlueprintPanel> _longTrouserPanels = [
  BlueprintPanel('Front panel', 'assets/blueprints/long_trouser_front.jpg', 0.7465, [
    BlueprintLabel('waist4', 'Waist ÷ 4', 0.4608, 0.0350, 0.6042, 0.0650, quarterTurns: 0),
    BlueprintLabel('crotch', 'Crotch', 0.4206, 0.1560, 0.4608, 0.2400, quarterTurns: 3),
    BlueprintLabel('seat4', 'Seat ÷ 4', 0.4622, 0.2740, 0.6028, 0.3040, quarterTurns: 0),
    BlueprintLabel('height', 'Height', 0.5291, 0.4450, 0.5660, 0.5390, quarterTurns: 3),
    BlueprintLabel('knee', 'Around knee', 0.4072, 0.5700, 0.6296, 0.6000, quarterTurns: 0),
    BlueprintLabel('end2', 'Round end ÷ 2', 0.4206, 0.8925, 0.6175, 0.9225, quarterTurns: 0),
  ]),
  BlueprintPanel('Back panel', 'assets/blueprints/long_trouser_back.jpg', 0.7465, [
    BlueprintLabel('waist4', 'Waist ÷ 4', 0.4528, 0.0425, 0.5733, 0.0725, quarterTurns: 0),
    BlueprintLabel('seat4p25', 'Seat ÷ 4 + 2.5', 0.4059, 0.3050, 0.6095, 0.3350, quarterTurns: 0),
    BlueprintLabel('height', 'Height', 0.4595, 0.4690, 0.4956, 0.5490, quarterTurns: 3),
    BlueprintLabel('fork', 'Crotch fork (Height − Crotch)', 0.3697, 0.4975, 0.4434, 0.7050, quarterTurns: 1),
  ]),
  BlueprintPanel('Waistband', 'assets/blueprints/trouser_waistband.jpg', 0.7465, [
    BlueprintLabel('waist', 'Waist', 0.6109, 0.4360, 0.6484, 0.5025, quarterTurns: 3),
  ]),
];

final List<BlueprintPanel> _shortTrouserPanels = [
  BlueprintPanel('Front panel', 'assets/blueprints/short_trouser_front.jpg', 0.7465, [
    BlueprintLabel('waist4', 'Waist ÷ 4', 0.4655, 0.0460, 0.6216, 0.0790, quarterTurns: 0),
    BlueprintLabel('crotch', 'Crotch', 0.3382, 0.2690, 0.3952, 0.3560, quarterTurns: 3),
    BlueprintLabel('seat', 'Seat', 0.5995, 0.3925, 0.6859, 0.4250, quarterTurns: 0),
    BlueprintLabel('htk15', 'Height till knee + 1.5', 0.5064, 0.4525, 0.5425, 0.7300, quarterTurns: 3),
  ]),
  BlueprintPanel('Back panel', 'assets/blueprints/short_trouser_back.jpg', 1.3396, [
    BlueprintLabel('h175', 'Height + 1.75', 0.2875, 0.4876, 0.7100, 0.5392, quarterTurns: 0),
    BlueprintLabel('seat4p25', 'Seat ÷ 4 + 2.5', 0.3260, 0.1822, 0.3580, 0.4742, quarterTurns: 1),
    BlueprintLabel('blank', '', 0.3260, 0.5399, 0.3580, 0.7180, quarterTurns: 1),
    BlueprintLabel('waist4p3', 'Waist ÷ 4 + 3', 0.9240, 0.3617, 0.9660, 0.7917, quarterTurns: 1),
  ]),
  BlueprintPanel('Waistband', 'assets/blueprints/trouser_waistband.jpg', 0.7465, [
    BlueprintLabel('waist', 'Waist', 0.6109, 0.4360, 0.6484, 0.5025, quarterTurns: 3),
  ]),
];

final List<BlueprintPanel> _shirtPanels = [
  BlueprintPanel('Front body (2 pieces)', 'assets/blueprints/shirt_front.jpg', 0.7467, [
    BlueprintLabel('shoulder', 'Shoulder', 0.3638, 0.1800, 0.5692, 0.2250, quarterTurns: 0),
    BlueprintLabel('c15', 'Allowance', 0.4799, 0.3358, 0.7344, 0.3700, quarterTurns: 0),
    BlueprintLabel('chestp05', 'Chest + 0.5', 0.2098, 0.5767, 0.5938, 0.6200, quarterTurns: 0),
  ]),
  BlueprintPanel('Back', 'assets/blueprints/shirt_back.jpg', 1.3393, [
    BlueprintLabel('chest4p2', 'Chest ÷ 4 + 2', 0.6250, 0.3962, 0.6600, 0.5402, quarterTurns: 1),
    BlueprintLabel('shoulder', 'Shoulder', 0.8817, 0.4844, 0.9667, 0.5558, quarterTurns: 0),
    BlueprintLabel('height', 'Height', 0.3983, 0.7321, 0.5617, 0.7969, quarterTurns: 0),
  ]),
  BlueprintPanel('Yoke (shoulder piece)', 'assets/blueprints/shirt_yoke.jpg', 1.3393, [
    BlueprintLabel('shoulder', 'Shoulder', 0.3800, 0.2054, 0.6200, 0.2812, quarterTurns: 0),
  ]),
  BlueprintPanel('Sleeve', 'assets/blueprints/shirt_sleeve.jpg', 1.3393, [
    BlueprintLabel('chest2', 'Chest ÷ 2', 0.5933, 0.3951, 0.8050, 0.4665, quarterTurns: 0),
    BlueprintLabel('sleevelen', 'Sleeve length', 0.4292, 0.5915, 0.5708, 0.6696, quarterTurns: 0),
    BlueprintLabel('sleeveopen', 'Sleeve opening', 0.3150, 0.9040, 0.6850, 0.9866, quarterTurns: 0),
  ]),
  BlueprintPanel('Collar', 'assets/blueprints/shirt_collar.jpg', 1.7917, [
    BlueprintLabel('collar', 'Collar size', 0.4201, 0.4427, 0.5799, 0.5156, quarterTurns: 0),
  ]),
];

