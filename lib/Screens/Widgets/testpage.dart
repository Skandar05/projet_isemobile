import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/Screens/Widgets/custom_app_bar.dart';
import 'package:test/Screens/parent/home_Parent.dart';
import 'package:test/providers/Pd_Providers.dart';
import 'package:test/providers/rdv_provider.dart';


class Testpage extends StatefulWidget {
  const Testpage({super.key});

  @override
  State<Testpage> createState() => _TestpageState();
}



class _TestpageState extends State<Testpage> {


  final Color primary = const Color(0xff1F4B8F);


  // =============================
  // PEDAGOGIQUES
  // =============================

  List<dynamic> pedagogiques = [];

  Map<String,dynamic>? selectedPedagogique;

  int? selectedPedagogiqueId;



  // =============================
  // DATE / SLOT
  // =============================

  int selectedWeekOffset = 0;

  int? selectedDayIndex;

  int? selectedSlotIndex;



  bool isLoading = false;

  String? errorMessage;



  final List<String> availableDays = [];

  final List<Map<String,String>> allSlots = [];

  final List<Map<String,String>> filteredSlots = [];

  final List<Map<String,String>> availableDates = [];

  final List<Map<String,String>> allDateSlots = [];

  final List<Map<String,String>> allDateOccurrences = [];



  // =============================
  // MOTIF
  // =============================

  final TextEditingController motifController =
      TextEditingController();



  @override
  void initState() {

    super.initState();

    _fetchPd();

  }



  @override
  void dispose(){

    motifController.dispose();

    super.dispose();

  }


  int idParent = 0;


  // =============================
  // LOAD PEDAGOGIQUES
  // =============================

  Future<void> _fetchPd() async {


    try{
      final prefs= await SharedPreferences.getInstance();
      idParent = prefs.getInt('idPersonne') ?? 0;
      final result =
      await RdvProvider().loadpd();
      final parentIdStr = prefs.getString('selectedTeacherParentId') ?? '';
      debugPrint('Selected Teacher Parent ID: $parentIdStr');


      for(final item in result){


        item['nom'] =
        "${item['Nomfr'] ?? ''} ${item['Prenomfr'] ?? ''}";


      }



      setState((){

        pedagogiques = result;

      });



    }
    catch(e){


      setState((){

        errorMessage =
            e.toString();

      });


    }


  }
  Future<int>creationrdv(int idParent, int idPedagogique, String date, String motif,String role , String timeStart, String timeEnd,) async {
    try {
      final result = await RdvProvider().createPDRdv(
      idpd: idPedagogique,
      idParent: idParent,
      date: date,
      motif: motif,
      role: 'parent',
      timeStart: timeStart,
      timeEnd: timeEnd,
    );
    return result;
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      return -1; // Return an error code or handle the error as needed
    }
    
  }






  // =============================
  // SELECT PEDAGOGIQUE
  // =============================

  Future<void> _onSelectPedagogique(int idPedagogique) async {


    final pd = pedagogiques.firstWhere(
      (item) => item['idpersonne']?.toString() == idPedagogique.toString(),
      orElse: () => {},
    );

    setState(() {
      selectedPedagogique = pd is Map<String, dynamic> && pd.isNotEmpty ? pd : null;
      selectedPedagogiqueId = idPedagogique;



      selectedDayIndex = null;

      selectedSlotIndex = null;



      availableDays.clear();

      allSlots.clear();

      filteredSlots.clear();

      availableDates.clear();

      allDateSlots.clear();

      allDateOccurrences.clear();


    });



    await _fetchDisponibilite(idPedagogique);


  }





  // =============================
  // LOAD DISPONIBILITE
  // =============================


  Future<void> _fetchDisponibilite(
      int idPedagogique
      ) async {


    setState((){

      isLoading=true;

      errorMessage=null;

    });



    try{


      final disponibilites =
      await PdProvider()
          .getAllDisponibilites(idPedagogique);




      final slotKeys=<String>{};



      for(final item in disponibilites){



        final jour =
        item['jour'].toString();



        if(!availableDays.contains(jour)){

          availableDays.add(jour);

        }




        final start =
        item['heuredebut'].toString();



        final end =
        item['heurefin'].toString();





        final slots =
        _generateSlots(
            start,
            end
        );




        for(final slot in slots){


          final key =
          "$jour-${slot['start']}-${slot['end']}";



          if(!slotKeys.contains(key)){


            slotKeys.add(key);



            allSlots.add({

              "jour":jour,

              "start":slot['start']!,

              "end":slot['end']!,

              "time":slot['time']!,


            });


          }


        }


      }




      _buildCalendarOccurrences();



    }
    catch(e){


      errorMessage =
          e.toString();


    }
    finally{


      setState((){

        isLoading=false;

      });


    }


  }






  // =============================
  // GENERATE 15 MIN SLOTS
  // =============================


  List<Map<String,String>> _generateSlots(
      String start,
      String end
      ){


    List<Map<String,String>> slots=[];



    final startValue =
        int.parse(start.split(":")[0])*60 +
            int.parse(start.split(":")[1]);



    final endValue =
        int.parse(end.split(":")[0])*60 +
            int.parse(end.split(":")[1]);





    for(
    int current=startValue;
    current+15<=endValue;
    current+=15
    ){



      final finish =
      current+15;



      String h1 =
      (current ~/60)
          .toString()
          .padLeft(2,'0');


      String m1 =
      (current%60)
          .toString()
          .padLeft(2,'0');



      String h2 =
      (finish ~/60)
          .toString()
          .padLeft(2,'0');



      String m2 =
      (finish%60)
          .toString()
          .padLeft(2,'0');




      slots.add({

        "start":"$h1:$m1",

        "end":"$h2:$m2",

        "time":
        "$h1:$m1 - $h2:$m2"


      });


    }



    return slots;


  }
    // =============================
  // DATE HELPERS
  // =============================


  DateTime _startOfWeek(DateTime date){

    return DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );

  }



  DateTime _currentWeekStart(){

    return _startOfWeek(
      DateTime.now()
    ).add(
      Duration(
        days:selectedWeekOffset * 7
      )
    );

  }




  String _formatDateKey(DateTime date){

    return
        "${date.year.toString().padLeft(4,'0')}-"
        "${date.month.toString().padLeft(2,'0')}-"
        "${date.day.toString().padLeft(2,'0')}";

  }




  String _formatWeekLabel(DateTime date){

    final end =
    date.add(
      const Duration(days:6)
    );


    return
    "Semaine du "
        "${date.day.toString().padLeft(2,'0')}/"
        "${date.month.toString().padLeft(2,'0')} "
        "au "
        "${end.day.toString().padLeft(2,'0')}/"
        "${end.month.toString().padLeft(2,'0')}";

  }






  // =============================
  // CREATE REAL CALENDAR DATES
  // =============================


  void _buildCalendarOccurrences(){


    allDateOccurrences.clear();

    allDateSlots.clear();



    final weekStart =
    _startOfWeek(
      DateTime.now()
    );


    final horizon =
    weekStart.add(
      const Duration(days:41)
    );



    final weekdays={

      "lundi":DateTime.monday,

      "mardi":DateTime.tuesday,

      "mercredi":DateTime.wednesday,

      "jeudi":DateTime.thursday,

      "vendredi":DateTime.friday,

      "samedi":DateTime.saturday,

      "dimanche":DateTime.sunday,

    };



    final slotKeys=<String>{};



    for(final day in availableDays){


      final target =
      weekdays[
      day.toLowerCase()
      ];



      if(target==null) {
        continue;
      }




      for(
      DateTime date=weekStart;
      !date.isAfter(horizon);
      date=date.add(
        const Duration(days:1)
      )
      ){



        if(date.weekday != target) {
          continue;
        }




        final apiDate =
        _formatDateKey(date);



        final label =
        "$day "
            "${date.day.toString().padLeft(2,'0')}/"
            "${date.month.toString().padLeft(2,'0')}";



        allDateOccurrences.add({

          "label":label,

          "value":apiDate,

          "jour":day,


        });




        for(final slot in allSlots){



          if(slot['jour'] != day) {
            continue;
          }



          final key =
          "$apiDate-${slot['start']}-${slot['end']}";



          if(!slotKeys.contains(key)){


            slotKeys.add(key);



            allDateSlots.add({


              "label":label,

              "value":apiDate,

              "jour":day,

              "start":slot['start']!,

              "end":slot['end']!,

              "time":slot['time']!,


            });



          }


        }



      }


    }




    allDateOccurrences.sort(
          (a,b)=>
      a['value']!
          .compareTo(
          b['value']!
      ),
    );



    allDateSlots.sort(
          (a,b){

        final date =
        a['value']!
            .compareTo(
            b['value']!
        );


        if(date!=0) {
          return date;
        }



        return
          a['start']!
              .compareTo(
              b['start']!
          );


      },
    );



    _applyWeekFilter();

  }






  // =============================
  // FILTER BY WEEK
  // =============================


  void _applyWeekFilter(){


    availableDates.clear();

    filteredSlots.clear();



    selectedDayIndex=null;

    selectedSlotIndex=null;




    final start =
    _currentWeekStart();



    final end =
    start.add(
      const Duration(days:6)
    );



    final today =
    DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );




    for(final date in allDateOccurrences){


      final parsed =
      DateTime.tryParse(
          date['value']!
      );



      if(parsed==null) {
        continue;
      }




      if(selectedWeekOffset==0 &&
          parsed.isBefore(today))
      {
        continue;
      }




      if(parsed.isBefore(start) ||
          parsed.isAfter(end))
      {
        continue;
      }




      availableDates.add(date);


    }




    availableDates.sort(
          (a,b)=>
      a['value']!
          .compareTo(
          b['value']!
      ),
    );


  }



  // =============================
  // CHANGE WEEK
  // =============================


  void _changeWeek(int value){


    if(selectedWeekOffset+value <0) {
      return;
    }

    setState((){


      selectedWeekOffset += value;


      _applyWeekFilter();


    });


  }







  // =============================
  // SELECT DATE
  // =============================


  void _selectDate(int index){


    final date =
    availableDates[index];



    final slots =
    allDateSlots.where((slot){


      return
        slot['value']==date['value'];


    }).toList();




    setState((){


      selectedDayIndex=index;


      selectedSlotIndex=null;



      filteredSlots

        ..clear()

        ..addAll(slots);



    });


  }





  // =============================
  // SELECT SLOT
  // =============================


  void _selectSlot(int index){


    setState((){


      selectedSlotIndex=index;


    });


  }

  @override
Widget build(BuildContext context) {

  return Scaffold(

    resizeToAvoidBottomInset: true,

    backgroundColor:
    const Color(0xffF5F7FB),


    appBar: CustomAppBar(

      interfacePage: HomeParent(),

      title: "Rendez-vous pédagogique",

      subtitle: "Créer un rendez-vous pédagogique",

      showBackButton: true,

    ),



    body: SafeArea(

      child: SingleChildScrollView(

        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior.onDrag,


        padding:
        const EdgeInsets.all(18),


        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [



            const Text(

              "Choisir un pédagogique",

              style: TextStyle(

                fontSize:20,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:12),



            Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal:16,
              ),


              decoration:BoxDecoration(

                color:Colors.white,

                borderRadius:
                BorderRadius.circular(18),


                border:Border.all(
                  color:
                  Colors.grey.shade300,
                ),

              ),



              child: DropdownButtonHideUnderline(

                child:
                DropdownButton<int>(

                  isExpanded:true,


                  value:selectedPedagogiqueId,


                  hint:
                  const Text(
                    "Sélectionnez un pédagogique",
                  ),



                  items:
                  pedagogiques.map((pd){
                    final idValue = int.tryParse(pd['idpersonne']?.toString() ?? '') ?? pd['idpersonne'] as int?;
                    return DropdownMenuItem<int>(
                      value:idValue,
                      child:
                      Text(
                        "${pd['Nomfr']} ${pd['Prenomfr']}",
                      ),
                    );
                  }).toList(),




                  onChanged:(value){


                    if(value!=null){

                      _onSelectPedagogique(value);

                    }


                  },


                ),

              ),

            ),





            const SizedBox(height:30),




            const Text(

              "CHOISIR UNE DATE",

              style:
              TextStyle(

                fontWeight:
                FontWeight.bold,

              ),

            ),




            const SizedBox(height:10),




            Row(

              children:[



                IconButton(

                  onPressed:
                  selectedWeekOffset>0
                      ? ()=>_changeWeek(-1)
                      : null,


                  icon:
                  const Icon(
                    Icons.chevron_left,
                  ),

                ),




                Expanded(

                  child:
                  Text(

                    _formatWeekLabel(
                      _currentWeekStart(),
                    ),


                    textAlign:
                    TextAlign.center,


                    style:
                    const TextStyle(

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),

                ),




                IconButton(

                  onPressed:
                  ()=>_changeWeek(1),


                  icon:
                  const Icon(
                    Icons.chevron_right,
                  ),

                ),


              ],

            ),






            const SizedBox(height:15),




            if(isLoading)

              const Center(

                child:
                CircularProgressIndicator(),

              )



            else if(errorMessage!=null)


              Container(

                padding:
                const EdgeInsets.all(12),


                decoration:
                BoxDecoration(

                  color:
                  Colors.red.shade50,


                  borderRadius:
                  BorderRadius.circular(12),

                ),


                child:
                Text(
                  errorMessage!,
                  style:
                  const TextStyle(
                    color:Colors.red,
                  ),
                ),

              )



            else ...[




              SizedBox(

                height:90,


                child:
                ListView.builder(

                  scrollDirection:
                  Axis.horizontal,


                  itemCount:
                  availableDates.length,


                  itemBuilder:(context,index){


                    final date =
                    availableDates[index];


                    final selected =
                    selectedDayIndex==index;



                    return GestureDetector(


                      onTap:(){

                        _selectDate(index);

                      },



                      child:Container(


                        width:130,


                        margin:
                        const EdgeInsets.only(
                          right:10,
                        ),



                        decoration:
                        BoxDecoration(


                          color:
                          selected
                              ? primary
                              : Colors.white,



                          borderRadius:
                          BorderRadius.circular(12),



                          border:Border.all(

                            color:
                            selected
                                ? Colors.blue
                                : Colors.grey.shade300,

                          ),

                        ),



                        child:
                        Column(

                          mainAxisAlignment:
                          MainAxisAlignment.center,


                          children:[


                            Text(

                              date['label']!,

                              textAlign:
                              TextAlign.center,


                              style:
                              TextStyle(

                                color:
                                selected
                                    ? Colors.white
                                    : Colors.black,


                                fontWeight:
                                FontWeight.bold,

                              ),

                            ),



                            const SizedBox(height:6),



                            Text(

                              "Créneaux disponibles",

                              style:
                              TextStyle(

                                color:
                                selected
                                    ? Colors.white70
                                    : Colors.grey,

                                fontSize:12,

                              ),

                            ),


                          ],

                        ),


                      ),


                    );


                  },


                ),

              ),




              const SizedBox(height:25),




              const Text(

                "CRÉNEAUX DISPONIBLES",

                style:
                TextStyle(

                  fontWeight:
                  FontWeight.bold,

                ),

              ),




              const SizedBox(height:15),




              GridView.builder(


                shrinkWrap:true,


                physics:
                const NeverScrollableScrollPhysics(),



                itemCount:
                filteredSlots.length,



                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(


                  crossAxisCount:2,


                  childAspectRatio:2.3,


                  crossAxisSpacing:10,


                  mainAxisSpacing:10,


                ),




                itemBuilder:(context,index){


                  final slot =
                  filteredSlots[index];


                  final selected =
                  selectedSlotIndex==index;



                  return GestureDetector(


                    onTap:
                    selectedDayIndex!=null

                    ? ()=>_selectSlot(index)

                    : null,



                    child:
                    Container(


                      decoration:
                      BoxDecoration(


                        color:
                        selected
                            ? primary
                            : Colors.white,



                        borderRadius:
                        BorderRadius.circular(12),



                        border:Border.all(

                          color:
                          selected
                              ? Colors.blue
                              : Colors.grey.shade300,

                        ),

                      ),



                      child:
                      Center(

                        child:
                        Text(

                          slot['time']!,


                          style:
                          TextStyle(

                            color:
                            selected
                                ? Colors.white
                                : Colors.black,


                            fontWeight:
                            FontWeight.w600,

                          ),

                        ),

                      ),

                    ),

                  );


                },


              ),


            ],





            const SizedBox(height:30),





            const Text(

              "Motif du rendez-vous",

              style:
              TextStyle(

                fontSize:18,

                fontWeight:
                FontWeight.bold,

              ),

            ),




            const SizedBox(height:12),




            Container(

              decoration:
              BoxDecoration(

                color:
                Colors.white,


                borderRadius:
                BorderRadius.circular(18),



                border:
                Border.all(
                  color:
                  Colors.grey.shade300,
                ),

              ),



              child:
              TextField(

                controller:
                motifController,
                onChanged: (_) => setState(() {}),

                minLines:3,

                maxLines:6,



                decoration:
                const InputDecoration(


                  hintText:
                  "Écrire le motif du rendez-vous...",


                  prefixIcon:
                  Icon(Icons.edit),



                  border:
                  InputBorder.none,


                  contentPadding:
                  EdgeInsets.all(16),


                ),


              ),

            ),






            const SizedBox(height:35),





            SizedBox(


              width:
              double.infinity,


              height:55,



              child:
              ElevatedButton.icon(



                icon:
                const Icon(
                  Icons.calendar_month,
                ),



                label:
                const Text(

                  "Créer un rendez-vous",

                  style:
                  TextStyle(
                    fontSize:16,
                  ),

                ),




                style:
                ElevatedButton.styleFrom(


                  backgroundColor:
                  selectedDayIndex!=null &&
                  selectedSlotIndex!=null &&
                  motifController.text.trim().isNotEmpty

                  ? primary

                  : Colors.grey,



                  foregroundColor:
                  Colors.white,



                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(18),

                  ),

                ),




                onPressed:
          
                selectedDayIndex!=null &&
                selectedSlotIndex!=null &&
                motifController.text.trim().isNotEmpty


                ? () async {


                  final dateValue = availableDates[selectedDayIndex!]['value'] ?? '';
                  final slot = filteredSlots[selectedSlotIndex!];
                  final motif = motifController.text.trim();

                  if (selectedPedagogiqueId == null || dateValue.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez sélectionner un pédagogique et une date valides.'),
                      ),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final result = await creationrdv(
                    idParent,
                    selectedPedagogiqueId!,
                    dateValue,
                    motif,
                    'parent',
                    slot['start']!,
                    slot['end']!,
                  );

                  if (!mounted) return;

                  if (result == 200 || result == 201) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Rendez-vous créé avec succès.'),
                      ),
                    );
                    setState(() {
                      selectedDayIndex = null;
                      selectedSlotIndex = null;
                      motifController.clear();
                      filteredSlots.clear();
                    });
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Échec de la création du rendez-vous. Code: $result'),
                      ),
                    );
                  }

                }

                : null,



              ),


            ),



          ],


        ),

      ),

    ),

  );

}

}