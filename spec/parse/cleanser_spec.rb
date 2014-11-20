# encoding: UTF-8

require 'spec_helper'

require 'slaw'

describe Slaw::Parse::Cleanser do
  describe '#remove_empty_lines' do
    it 'should remove empty lines' do
      subject.remove_empty_lines("foo\n  \n\n  bar\n\n\nbaz\n").should == "foo\n  bar\nbaz"
    end
  end

  describe '#unbreak_lines' do
    it 'should unbreak simple lines' do
      subject.unbreak_lines("""
8.2.3 an additional fee or tariff, which is
to be determined by the City in its
sole discretion, in respect of additional
costs incurred or services.
8.3 In the event that a person qualifies for
a permit, but has motivated in writing
the inability to pay the fee contemplated.""").should == """
8.2.3 an additional fee or tariff, which is to be determined by the City in its sole discretion, in respect of additional costs incurred or services.
8.3 In the event that a person qualifies for a permit, but has motivated in writing the inability to pay the fee contemplated."""
    end

    it 'should not unbreak section headers' do
      subject.unbreak_lines("""
8.4.3 must be a South African citizen, failing which, must be in possession of
a valid work permit which includes, but is not limited to, a refugee
permit; and
8.4.4 must not employ and actively utilise the services of more than 20
(twenty) persons.""").should == """
8.4.3 must be a South African citizen, failing which, must be in possession of a valid work permit which includes, but is not limited to, a refugee permit; and
8.4.4 must not employ and actively utilise the services of more than 20
(twenty) persons."""
    end
  end

  describe '#break_lines' do
    it 'should break nested lists' do
      subject.break_lines('stored, if known; (b) the number of trolleys').should == "stored, if known;\n(b) the number of trolleys"

      subject.break_lines("(5) The officer-in-Charge may – (a) remove all withered natural flowers, faded or damaged artificial flowers and any receptacle placed on a grave; or\n(b) 30 days after publishing a general").should == "(5) The officer-in-Charge may –\n(a) remove all withered natural flowers, faded or damaged artificial flowers and any receptacle placed on a grave; or\n(b) 30 days after publishing a general"

      subject.break_lines("(2) No person may – (a) plant, cut or remove plants, shrubs or flowers on a grave without the permission of the officer-in-charge; (b) plant, cut or remove plants, shrubs or flowers on the berm section; or").should == "(2) No person may –\n(a) plant, cut or remove plants, shrubs or flowers on a grave without the permission of the officer-in-charge;\n(b) plant, cut or remove plants, shrubs or flowers on the berm section; or"

      subject.break_lines('(b) its successor in title; or (c) a structure or person exercising a delegated power or carrying out an instruction, where any power in these By-laws, has been delegated or sub-delegated or an instruction given as contemplated in, section 59 of the Local Government: Municipal Systems Act, 2000 (Act No. 32 of 2000); or (d) a service provider fulfilling a responsibility under these By-laws, assigned to it in terms of section 81(2) of the Local Government: Municipal Systems Act, 2000, or any other law, as the case may be;').should == "(b) its successor in title; or\n(c) a structure or person exercising a delegated power or carrying out an instruction, where any power in these By-laws, has been delegated or sub-delegated or an instruction given as contemplated in, section 59 of the Local Government: Municipal Systems Act, 2000 (Act No. 32 of 2000); or\n(d) a service provider fulfilling a responsibility under these By-laws, assigned to it in terms of section 81(2) of the Local Government: Municipal Systems Act, 2000, or any other law, as the case may be;"
    end

    it 'should break at likely subsections' do
      subject.break_lines('(c) place a metal cot on any grave. (3) A person may only erect, place or leave, an object or decoration on a grave during the first 30 days following the burial. (4) Natural or artificial flowers contained in receptacles may be placed on a grave at any time, but in a grave within a berm section or with a headstone, such flowers may only be placed in the socket provided. (5) The officer-in-Charge may – (a) remove all withered natural flowers, faded or damaged artificial flowers and any receptacle placed on a grave; or').should == "(c) place a metal cot on any grave.\n(3) A person may only erect, place or leave, an object or decoration on a grave during the first 30 days following the burial.\n(4) Natural or artificial flowers contained in receptacles may be placed on a grave at any time, but in a grave within a berm section or with a headstone, such flowers may only be placed in the socket provided.\n(5) The officer-in-Charge may – (a) remove all withered natural flowers, faded or damaged artificial flowers and any receptacle placed on a grave; or"
    end

    it 'should break lines at likely section titles' do
      subject.break_lines('foo bar. New section title 62. (1) For the purpose').should == "foo bar.\nNew section title\n62. (1) For the purpose"
      subject.break_lines('New section title 62. (1) For the purpose').should == "New section title\n62. (1) For the purpose"
    end

    it 'should clean up wrapped definition lines after pdf' do
      subject.break_lines('“agricultural holding” means a portion of land not less than 0.8 hectares in extent used solely or mainly for the purpose of agriculture, horticulture or for breeding or keeping domesticated animals, poultry or bees; “approved” means as approved by the Council; “bund wall” means a containment wall surrounding an above ground storage tank, constructed of an impervious material and designed to contain 110% of the contents of the tank; “certificate of fitness” means a certificate contemplated in section 20; “certificate of registration” means a certificate contemplated in section 35;').should == "“agricultural holding” means a portion of land not less than 0.8 hectares in extent used solely or mainly for the purpose of agriculture, horticulture or for breeding or keeping domesticated animals, poultry or bees;\n“approved” means as approved by the Council;\n“bund wall” means a containment wall surrounding an above ground storage tank, constructed of an impervious material and designed to contain 110% of the contents of the tank;\n“certificate of fitness” means a certificate contemplated in section 20;\n“certificate of registration” means a certificate contemplated in section 35;"
    end

    it 'should break at CAPCASE TO Normal Case' do
      subject.break_lines('CHAPTER 3 PARKING METER PARKING GROUNDS Place of parking 7. No person may park or cause or permit to be parked any vehicle or allow a vehicle to be or remain in a parking meter parking ground otherwise than in a parking bay.').should == "CHAPTER 3 PARKING METER PARKING GROUNDS\nPlace of parking 7. No person may park or cause or permit to be parked any vehicle or allow a vehicle to be or remain in a parking meter parking ground otherwise than in a parking bay."
    end
  end

  describe '#strip_toc' do
    it 'should handle no toc' do
      s = "City of Johannesburg Metropolitan Municipality
CULTURE AND RECREATION BY-LAWS ( )PUBLISHED IN PROVINCIAL GAZETTE EXTRAORDINARY NO 179 DATED 21 MAY 2004 UNDER NOTICE NUMBER 825

CITY OF JOHANNESBURG METROPOLITAN MUNICIPALITY
CULTURE AND RECREATION BY-LAWS
The Municipal Manager of the City of Johannesburg Metropolitan Municipality hereby, in terms of Section 13(a) of the Local Government: Municipal Systems Act, 2000 (Act No. 32 of 2000), publishes the Culture and RecreationBy-laws for the City of Johannesburg Metropolitan Municipality, as approved by its Council, as set out hereunder.
CITY OF JOHANNESBURG METROPOLITAN MUNICIPALITY
CULTURE AND RECREATION BY-LAWS
CHAPTER 1 LIBRARY AND INFORMATION SERVICES
Definitions and interpretation
1. (1) In this Chapter, unless the context otherwise indicates-"
      subject.strip_toc(s).should == s
    end

    it 'should strip table of contents' do
      subject.strip_toc("City of Johannesburg Metropolitan Municipality
CULTURE AND RECREATION BY-LAWS ( )PUBLISHED IN PROVINCIAL GAZETTE EXTRAORDINARY NO 179 DATED 21 MAY 2004 UNDER NOTICE NUMBER 825

CITY OF JOHANNESBURG METROPOLITAN MUNICIPALITY
CULTURE AND RECREATION BY-LAWS
The Municipal Manager of the City of Johannesburg Metropolitan Municipality hereby, in terms of Section 13(a) of the Local Government: Municipal Systems Act, 2000 (Act No. 32 of 2000), publishes the Culture and RecreationBy-laws for the City of Johannesburg Metropolitan Municipality, as approved by its Council, as set out hereunder.
CITY OF JOHANNESBURG METROPOLITAN MUNICIPALITY
CULTURE AND RECREATION BY-LAWS
TABLE OF CONTENTS
CHAPTER 1
LIBRARY AND INFORMATION SERVICES
1. Definitions and interpretation 2. Admission to library buildings 3. Membership 4. Loan of library material 5. Return of library material 6. Overdue library material 7. Reservation of library material 8. Lost and damaged library material 9. Handling of library material 10. Exposure of library material to notifiable and infectious diseases 11. Library material for special and reference purposes 12. Reproduction of library material and objects and use of facsimile facilities 13. Library hours 14. Hire and use of auditoria and lecture rooms or library space 15. Internet viewing stations 16. Hiring of multimedia library space 17. Performing arts library 18. Availability of By-laws and notices in a library 19. Conduct in the libraries
CHAPTER 2
ARTS AND CULTURE AND COMMUNITY CENTRE FACILITIES

Part 1: Hire and use of community arts & culture facilities
20. Definitions and interpretation 21. Rights and status of artists 22. Co-operation between Council departments 23. Application for hiring of premises 24. Prescribed fees 25. Payment of fees 26. Period of hire 27. Adjustment of period of hire 28. Joint hire 29. Sub-letting 30. Condition of premises 31. Duties of the hirer 32. Advertisements and decorations 33. Admissions and sale of tickets 34. Overcrowding 35. Sale of refreshments 36. Services 37. Cancellation due to destruction of premises 38. Cancellation due to non-compliance 39. Termination of period of hire 40 Fire hazards and Insurance 41. Storage facilities 42. Equipment 43. Right of entry 44. Inspection 45. Regulations 46. Nuisance
Part 2: Community centres
47. Group activities 48. Membership 49. Membership fees 50. Use of centres for religious or personal purposes 51. Dress code 52. Conduct of children 53. Application of certain sections of part 1 of Chapter 2 to centres 54. Application of certain sections of Part 2 of Chapter 3 to centres

CHAPTER 3
RECREATION AND SPORT
Part 1: Camping and caravan parks
55. Definitions and interpretation 56. Lighting of fires prohibited 57. Permits 58. Extension of permits 59. Limitation on the period of occupancy of a camping site 60. Allocation and Use of sites 61. Proper use of roads and pathways 62. Reservation of sites 63. Right of refusal to issue or renew permits 64. Obligations of permit holders 65. Cancellation of permits 66. Access and loitering by members of the public prohibited 67. Site to be left in a clean condition 68. Washing of clothes and utensils and preparation of foodstuffs 69. Trading without permission 70. Damage to Vegetation or Property 71. Instructions of camping officer to be complied with 72 Registration and use of firearms 73. Protection of wildlife 74. Special requirements regarding caravan parks and caravans
Part 2: Sport Facilities
75. Definitions and interpretation 76. Administration 77. Access conditions 78. Smoking 79. Alcoholic beverages 80. Duties of hirer 81. Dress code 82. Hiring of sport facilities 83. Reservation of sport facilities by the Council 84. Group activities 85. Public decency 86. Clothing and personal effects 87. Prescribed fees 88. Generally prohibited conduct 89. Animals 90. Infectious Diseases 91. Firearms and Traditional Weapons 92. Disturbance by sound systems 93. Sale of food and refreshments 94. Filming and photographs 95. Sport advisory forum

CHAPTER 4 MISCELLANEOUS 96. Definitions and interpretation 97. Animals in facilities 98. Liability for acts and omissions 99. Offences and penalties 100.
Repeal
SCHEDULE 1 BY-LAWS REPEALED
CHAPTER 1 LIBRARY AND INFORMATION SERVICES
Definitions and interpretation
1. (1) In this Chapter, unless the context otherwise indicates-").should == "City of Johannesburg Metropolitan Municipality
CULTURE AND RECREATION BY-LAWS ( )PUBLISHED IN PROVINCIAL GAZETTE EXTRAORDINARY NO 179 DATED 21 MAY 2004 UNDER NOTICE NUMBER 825

CITY OF JOHANNESBURG METROPOLITAN MUNICIPALITY
CULTURE AND RECREATION BY-LAWS
The Municipal Manager of the City of Johannesburg Metropolitan Municipality hereby, in terms of Section 13(a) of the Local Government: Municipal Systems Act, 2000 (Act No. 32 of 2000), publishes the Culture and RecreationBy-laws for the City of Johannesburg Metropolitan Municipality, as approved by its Council, as set out hereunder.
CITY OF JOHANNESBURG METROPOLITAN MUNICIPALITY
CULTURE AND RECREATION BY-LAWS
CHAPTER 1 LIBRARY AND INFORMATION SERVICES
Definitions and interpretation
1. (1) In this Chapter, unless the context otherwise indicates-"
    end
  end

  describe '#remove_boilerplate' do
    it 'should handle no toc' do
      s = "(2)The provisions of section 12 (1) (a), (b), (d) and (g) and section 12(2), (3), (4) and (5), read with the necessary changes, apply to the taking into custody of cats.\nClaiming of impounded dogs and cats\n_____________________________________________________________________________________________ ___________ By-laws relating to Dogs and Cats for Promulgation\n14. (1) Any person may claim an impounded dog or cat if he or she –\n(a) satisfies the poundmaster that he or she is the owner or is otherwise entitled to the custody of the dog or cat concerned;"

      subject.remove_boilerplate(s).should == "(2)The provisions of section 12 (1) (a), (b), (d) and (g) and section 12(2), (3), (4) and (5), read with the necessary changes, apply to the taking into custody of cats.\nClaiming of impounded dogs and cats\n\n14. (1) Any person may claim an impounded dog or cat if he or she –\n(a) satisfies the poundmaster that he or she is the owner or is otherwise entitled to the custody of the dog or cat concerned;"
    end
  end
end
