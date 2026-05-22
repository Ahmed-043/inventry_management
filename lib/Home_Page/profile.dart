import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../colors.dart';
import '../Database/database.dart';
import '../Database/db_info.dart';
import '../Shared_Widgets/fonts.dart';
import '../Shared_Widgets/main_ui_helper.dart';
import '../Shared_Widgets/upload_circle.dart';

class ProfileSettings extends StatefulWidget {
  final DBInfo info;
  final VoidCallback onSave;

  const ProfileSettings({super.key, required this.info, required this.onSave});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController locController;
  late TextEditingController phoneController;
  Uint8List? selectedImage;
  final FocusNode nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.info.dbName);
    descController = TextEditingController(text: widget.info.description);
    locController = TextEditingController(text: widget.info.location);
    phoneController = TextEditingController(text: widget.info.phone);
    selectedImage = widget.info.image;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width < 780 ? 500 :  750,
      height: MediaQuery.of(context).size.width < 780 ? 750 : 500,
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24,bottom: 10),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        border: UiHelper.myBorder(),
        boxShadow: UiHelper.myBoxShadow(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile Settings', style: MyFont.semiBold(22, color: MyColors.darkBlue)),
              IconButton(
                  onPressed: () {
                    if(mounted){
                      Navigator.pop(context);
                    }
                  },
                  icon:  Icon(Icons.close, color: MyColors.grey, size: 25)),
            ],
          ),
          const Divider(height: 40),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 40,
                  runSpacing: 20,
                  crossAxisAlignment: .start,
                  alignment: .center,
                  children: [
                    /// Left Side: Image and Photo Actions
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: UploadCircle(
                          image: selectedImage,
                          onFileSelected: (file) => setState(() => selectedImage = file),
                        ),
                      ),
                    ),

                    /// Right Side: Form Fields
                    SizedBox(
                      width: 450,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("DB Name", isRequired: true),
                          UiHelper.myTextField(
                          focusNode: nameFocus,
                          controller: nameController,hint: 'ProductCatalog_DB'),
                          const SizedBox(height: 15),

                          _buildLabel("Address"),
                          UiHelper.myTextArea(
                              controller: locController,
                              hint: 'Town, City, Country',
                            maxLines: 3
                          ),
                          const SizedBox(height: 15),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Description"),
                                    UiHelper.myTextField(
                                      controller: descController,
                                      hint: 'Description',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Phone"),
                                    UiHelper.myTextField(
                                        controller: phoneController,
                                        hint: '+92',
                                      textType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
                                        LengthLimitingTextInputFormatter(15),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10,),
          /// Action Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: .end,
              children: [
                SizedBox(
                  width: 140,
                  height: 50,
                  child: UiHelper.myButton(
                    callback: () => Navigator.pop(context),
                    filled: false,
                    title: 'Close',
                    textSize: 14
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  height: 50,
                  child: UiHelper.myButton(
                    callback: () {
                      save();
                    },
                    filled: true,
                    color: MyColors.primary,
                    title: 'Save',
                    textSize: 14
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: MyFont.normal(14, color: MyColors.black),
          children: isRequired
              ? [const TextSpan(text: ' *', style: TextStyle(color: MyColors.error))]
              : [],
        ),
      ),
    );
  }

  save() async {
    if(nameController.text.trim().isEmpty){
      UiHelper.showToast(context, "Name can't be empty!",type:2);
      FocusScope.of(context).requestFocus(nameFocus);
      return;
    }
    widget.info.dbName = nameController.text;
    widget.info.description = descController.text;
    widget.info.location = locController.text;
    widget.info.phone = phoneController.text;
    widget.info.image = selectedImage;
    bool success = await updateDBInfo(currentDB!, widget.info);
    if(success && mounted){
      UiHelper.showToast(context, 'Updated Successfully',type:1);
      widget.onSave();
    }else{
      UiHelper.showToast(context, 'Failed to Update !',type:3);
    }
  }

}