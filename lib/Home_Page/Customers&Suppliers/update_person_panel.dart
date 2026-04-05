import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/upload_circle.dart';
import '../../Database/database.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../Shared_Widgets/upload_box.dart';
import '../../colors.dart';
import '../Products_Panel/delete_confirmation.dart';

class UpdatePersonPanel extends StatefulWidget {
  final Person person;
  final VoidCallback callback;
  const UpdatePersonPanel({
    super.key,
    required this.person,
    required this.callback,
  });

  @override
  State<UpdatePersonPanel> createState() => _UpdatePersonPanelState();
}

class _UpdatePersonPanelState extends State<UpdatePersonPanel> {
  late Uint8List? image;
  late bool isCustomer = widget.person.personType == 'customer' ? true : false;
  late bool isMajor = widget.person.type == 'major' ? true : false;
  final FocusNode _focusNode = FocusNode();

  late TextEditingController nameController = TextEditingController(
    text: widget.person.name,
  );
  late TextEditingController phoneController = TextEditingController(
    text: widget.person.phone,
  );
  late TextEditingController emailController = TextEditingController(
    text: widget.person.email,
  );
  late TextEditingController addressController = TextEditingController(
    text: widget.person.address,
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    image = widget.person.image;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true, // listens right away

      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          insertPerson();
          widget.callback();
        }
        

      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 40,
                        child: Text(
                          "Update Personal Information",
                          style: MyFont.normal(20),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        //width: 350,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: UploadCircle(
                            image: image,
                            onFileSelected: (file) {
                              image = file;
                              // 🔹 do something with the selected file
                              debugPrint("User selected: ${image?.length}");
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      UiHelper.myTextField(
                        label: "Name",
                        hint: 'Alex',
                        borderRadius: 15,
                        controller: nameController,
                        fontSize: 20,
                      ),
                      const SizedBox(height: 20),

                      UiHelper.myTextField(
                        label: "Phone",
                        hint: '+92 000 000 0000',
                        borderRadius: 15,
                        controller: phoneController,
                        fontSize: 20,
                        textType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
                          LengthLimitingTextInputFormatter(15),
                        ],
                      ),
                      const SizedBox(height: 20),

                      UiHelper.myTextField(
                        label: "Email",
                        hint: 'example@email.com',
                        borderRadius: 15,
                        controller: emailController,
                        fontSize: 20,
                        textType: TextInputType.emailAddress,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9@._\-+]'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: 100,
                        child: UiHelper.myTextArea(
                          label: "Address",
                          hint: 'Town,City,Country',
                          fontSize: 20,
                          controller: addressController,
                          maxLines: 3,
                        ),
                      ),

                      //const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            spacing: 50,
                            children: [
                              Text("Business Type", style: MyFont.semiBold(17)),

                              //  Expanded(child:SizedBox()),
                              SizedBox(
                                width: 250,
                                child: Center(
                                  child: Row(
                                    //crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),

                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                isMajor = !(isMajor);
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadiusGeometry.only(
                                                      topLeft: Radius.circular(
                                                        10,
                                                      ),
                                                      bottomLeft: Radius.circular(
                                                        10,
                                                      ),
                                                    ),
                                              ),
                                              backgroundColor: isMajor
                                                  ? MyColors.primary
                                                  : MyColors.info,
                                            ),
                                            child: Text(
                                              isMajor ? "Major" : "Local",
                                              style: MyFont.normal(
                                                15,
                                                color: MyColors.translucent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                isCustomer = !(isCustomer);
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadiusGeometry.only(
                                                      topRight: Radius.circular(
                                                        10,
                                                      ),
                                                      bottomRight:
                                                          Radius.circular(10),
                                                    ),
                                              ),

                                              backgroundColor: isCustomer
                                                  ? MyColors.success
                                                  : MyColors.blue,
                                            ),
                                            child: Text(
                                              isCustomer
                                                  ? "Customer"
                                                  : "Supplier",
                                              style: MyFont.normal(
                                                15,
                                                color: MyColors.translucent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SizedBox(
                //  color: Colors.red,
                width: double.infinity,
                child: Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    verticalDirection: VerticalDirection.up,
                    spacing: 20,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 2.5),
                        height: 40,
                        width: 140,
                        child: UiHelper.myButton(
                          title: 'Delete',
                          filled: true,
                          color: MyColors.error,
                          callback: () {
                            delete();
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 2.5),
                        height: 40,
                        width: 140,
                        child: UiHelper.myButton(
                          title: 'Close',
                          callback: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 2.5),
                        height: 40,
                        width: 140,
                        child: UiHelper.myButton(
                          title: 'Save',
                          filled: true,
                          callback: () async {
                            insertPerson();
                            widget.callback();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> insertPerson() async {
    final id = await updatePerson(
      currentDB!,
      id: widget.person.id!,
      name: nameController.text,
      phone: phoneController.text,
      email: emailController.text,
      address: addressController.text,
      image: image,
      personType: isCustomer ? "customer" : "supplier",
      type: isMajor ? "major" : "local",
    );
    errorDisplay(id);
    debugPrint("Update: $id");
    return id;
  }

  errorDisplay(int id, {String e = ''}) {
    if (id != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An Error Occurred while Saving info $e")),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  delete() async {

    try {
      showDeleteDialog(
        context: context,
        onDeleted: () async {
          deletePerson(currentDB!,widget.person.id!);
          Navigator.of(context).pop();
          widget.callback();
        },
      );
    } catch (e) {
      errorDisplay(0, e: e.toString());
      debugPrint(e.toString());
    }
  }
}
