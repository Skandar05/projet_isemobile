import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/Screens/parent/rendezvous_screen.dart';
import 'package:test/providers/Rdv_provider.dart';
import 'package:test/Screens/parent/ChooseCreneauScreen.dart';


class ChooseContactScreen extends StatefulWidget {
  const ChooseContactScreen({super.key});

  @override
  State<ChooseContactScreen> createState() => _ChooseContactScreenState();
}


class _ChooseContactScreenState extends State<ChooseContactScreen> {

  int? selectedIndex;


  @override
  void initState() {
    super.initState();

    Future.microtask(() {
       Provider.of<RdvProvider>(context, listen: false)
          .checkRole(
            role: "parent",
            context: context,
          ); 
          
    });
  }


  @override
  Widget build(BuildContext context) {

    final Color primary = const Color(0xff1F4B8F);

    final rdvProvider = Provider.of<RdvProvider>(context);

    final enseignants = rdvProvider.enseignants;


    return Scaffold(

      backgroundColor: const Color(0xffF5F7FB),

      body: SafeArea(

        child: Column(

          children: [


            const SizedBox(height: 10),


            // HEADER

            Padding(

              padding: const EdgeInsets.symmetric(horizontal:18),

              child: Row(

                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,


                children: [


                  InkWell(

                    onTap: (){
                       
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RendezVousPage(),
                    ),
                  );
                
                    },

                    child: CircleAvatar(

                      backgroundColor: Colors.white,

                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size:18,
                        color:primary,
                      ),

                    ),

                  ),



                  Row(

                    children: [

                      CircleAvatar(

                        backgroundColor:Colors.white,

                        child: Icon(
                          Icons.notifications_none,
                          color:primary,
                        ),

                      ),


                      const SizedBox(width:10),



                      CircleAvatar(

                        backgroundColor:primary,

                        child: ClipOval(

                          child: Image.asset(
                            'lib/images/logoise.png',
                            fit:BoxFit.cover,
                          ),

                        ),

                      )

                    ],

                  )

                ],

              ),

            ),



            const SizedBox(height:15),



            const Text(

              'Choisir un contact',

              style:TextStyle(

                fontSize:24,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:15),




            // STEP INDICATOR

            Padding(

              padding:
                  const EdgeInsets.symmetric(horizontal:20),

              child: Row(

                children:[

                  _buildStep(1,true),

                  _buildStepLine(),

                  _buildStep(2,false),

                  _buildStepLine(),

                  _buildStep(3,false),

                ],

              ),

            ),



            const SizedBox(height:10),




            // LIST

            Expanded(

              child: enseignants.isEmpty

                  ? const Center(
                      child:CircularProgressIndicator(),
                    )


                  : ListView.builder(

                      padding:
                          const EdgeInsets.symmetric(horizontal:20),


                      itemCount:enseignants.length,


                      itemBuilder:(context,index){


                        final e = enseignants[index];


                        return GestureDetector(


                          onTap:() async {


                            setState(() {

                              selectedIndex=index;

                            });



                            final fullname =
                                "${e['Nomfr']} ${e['Prenomfr']}";



                            await rdvProvider
                                .selectEnseignant(fullname);



                            await rdvProvider
                                .saveSelectedEnseignant(

                                  id: rdvProvider
                                      .idEnseignant
                                      .toString(),

                                  fullname:fullname,


                                  matiere:
                                      e['Nommatierefr'] ?? '',

                                );

                          },



                          child:_buildContactCard(

                            e,

                            selectedIndex == index,

                          ),


                        );

                      },

                    ),

            ),





            // BUTTON


            Padding(

              padding:
                  const EdgeInsets.all(20),


              child:SizedBox(

                width:double.infinity,

                height:56,


                child:ElevatedButton(


                  onPressed:selectedIndex == null

                      ? null

                      : (){


                          Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChooseCreneauScreen(),
                    ),
                  );


                        },



                  style:
                  ElevatedButton.styleFrom(


                    backgroundColor:

                    selectedIndex == null

                    ? Colors.grey.shade200

                    : primary,



                    foregroundColor:

                    selectedIndex == null

                    ? Colors.black54

                    : Colors.white,



                    elevation:0,


                    shape:
                    RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(12),

                    ),

                  ),



                  child:const Text(

                    'Continuer →',

                    style:TextStyle(

                      fontSize:16,

                      fontWeight:
                      FontWeight.w600,

                    ),

                  ),

                ),

              ),

            ),


          ],

        ),

      ),

    );

  }






  Widget _buildContactCard(
      Map<String,dynamic> e,
      bool isSelected,
  ){


    return Container(


      margin:
      const EdgeInsets.only(bottom:12),


      padding:
      const EdgeInsets.all(16),



      decoration:BoxDecoration(


        color:isSelected

            ? const Color(0xffE3F2FD)

            : Colors.white,



        borderRadius:
        BorderRadius.circular(12),



        border:Border.all(

          color:isSelected

              ? const Color(0xff1F4B8F)

              : Colors.transparent,


          width:2,

        ),

      ),



      child:Row(


        children:[


          const CircleAvatar(

            backgroundColor:Colors.grey,

            child:Icon(Icons.person),

          ),



          const SizedBox(width:16),




          Expanded(


            child:Column(


              crossAxisAlignment:
              CrossAxisAlignment.start,


              children:[


                Text(

                  "${e['Nomfr']} ${e['Prenomfr']}",

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.w600,

                  ),

                ),



                Text(

                  e['Nommatierefr'] ?? '',

                  style:
                  TextStyle(

                    color:
                    Colors.grey.shade600,

                  ),

                ),


              ],


            ),

          ),



        ],


      ),


    );


  }






  Widget _buildStep(
      int number,
      bool active
  ){

    return Container(

      width:28,

      height:28,


      decoration:BoxDecoration(

        shape:BoxShape.circle,


        color:active

        ? const Color(0xFF1E88E5)

        : Colors.grey.shade300,

      ),


      child:Center(

        child:Text(

          number.toString(),

          style:TextStyle(

            color:active

            ? Colors.white

            : Colors.grey,


            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),

    );

  }






  Widget _buildStepLine(){

    return Expanded(

      child:Container(

        height:2,

        color:Colors.grey.shade300,

      ),

    );

  }

}