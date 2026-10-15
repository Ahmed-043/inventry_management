import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
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
  void dispose() {
    nameController.dispose();
    descController.dispose();
    locController.dispose();
    phoneController.dispose();
    nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isPhone;
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = isPhone ? (screenWidth - 60) : 450.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isPhone ? (screenWidth-24) : (screenWidth < 780 ? 500 : 750),
          constraints: BoxConstraints(
            maxHeight: isPhone ? (MediaQuery.of(context).size.height * 0.88) : 750,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 12 : 24,
            vertical: isPhone ? 12 : 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: UiHelper.myBorder(),
            boxShadow: UiHelper.myBoxShadow(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile Settings',
                    style: MyFont.semiBold(isPhone ? 18 : 22, color: MyColors.darkBlue),
                  ),
                  IconButton(
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    icon: Icon(Icons.close, color: MyColors.grey, size: isPhone ? 20 : 25),
                  ),
                ],
              ),
              Divider(height: isPhone ? 16 : 40),
              Flexible(
                child: SingleChildScrollView(
                  child: Center(
                    child: Wrap(
                      spacing: isPhone ? 12 : 40,
                      runSpacing: isPhone ? 12 : 20,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          height: isPhone ? 150 : 200,
                          width: isPhone ? 150 : 200,
                          child: UploadCircle(
                            image: selectedImage,
                            onFileSelected: (file) => setState(() => selectedImage = file),
                          ),
                        ),
                        SizedBox(
                          width: formWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("DB Name", isRequired: true),
                              UiHelper.myTextField(
                                focusNode: nameFocus,
                                controller: nameController,
                                hint: 'ProductCatalog_DB',
                                fontSize: isPhone ? 13 : 15,
                              ),
                              const SizedBox(height: 12),
                              _buildLabel("Address"),
                              UiHelper.myTextArea(
                                controller: locController,
                                hint: 'Town, City, Country',
                                maxLines: 2,
                                fontSize: isPhone ? 13 : 15,
                              ),
                              const SizedBox(height: 12),
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
                                          fontSize: isPhone ? 13 : 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Phone"),
                                        UiHelper.myTextField(
                                          controller: phoneController,
                                          hint: '+92',
                                          textType: TextInputType.phone,
                                          fontSize: isPhone ? 13 : 15,
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    flex: isPhone ? 1 : 0,
                    child: SizedBox(
                      width: isPhone ? null : 130,
                      height: 40,
                      child: UiHelper.myButton(
                        callback: () => Navigator.pop(context),
                        filled: false,
                        title: 'Close',
                        textSize: isPhone ? 13 : 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: isPhone ? 1 : 0,
                    child: SizedBox(
                      width: isPhone ? null : 130,
                      height: 40,
                      child: UiHelper.myButton(
                        callback: save,
                        filled: true,
                        color: MyColors.primary,
                        title: 'Save',
                        textSize: isPhone ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: text,
          style: MyFont.normal(13, color: MyColors.black),
          children: isRequired
              ? [const TextSpan(text: ' *', style: TextStyle(color: MyColors.error))]
              : [],
        ),
      ),
    );
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      UiHelper.showToast(context, "Name can't be empty!", type: 2);
      FocusScope.of(context).requestFocus(nameFocus);
      return;
    }
    widget.info.dbName = nameController.text.trim();
    widget.info.description = descController.text.trim();
    widget.info.location = locController.text.trim();
    widget.info.phone = phoneController.text.trim();
    widget.info.image = selectedImage;
    bool success = await updateDBInfo(currentDB!, widget.info);
    if (success && mounted) {
      UiHelper.showToast(context, 'Updated Successfully', type: 1);
      widget.onSave();
      Navigator.pop(context);
    } else if (mounted) {
      UiHelper.showToast(context, 'Failed to Update!', type: 3);
    }
  }
}
