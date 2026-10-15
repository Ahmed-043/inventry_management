import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
import 'package:inventry_management/Shared_Widgets/upload_circle.dart';
import '../../Database/database.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';

class AddNewPersonPanel extends StatefulWidget {
  final bool isCustomer;
  final VoidCallback callback;
  const AddNewPersonPanel({super.key, this.isCustomer = true, required this.callback});

  @override
  State<AddNewPersonPanel> createState() => _AddNewPersonPanelState();
}

class _AddNewPersonPanelState extends State<AddNewPersonPanel> {
  Uint8List? image;
  late bool isCustomer = widget.isCustomer;
  late bool major = false;
  late Person person;
  final FocusNode _focusNode = FocusNode();

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void insertPerson() async {
    if (nameController.text.trim().isEmpty) {
      UiHelper.showToast(context, 'Person Name Can\'t be empty', type: 3);
      return;
    }

    try {
      person = Person(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        personType: isCustomer ? 'customer' : 'supplier',
        type: major ? 'major' : 'local',
        image: image,
      );

      final existingMaps = await currentDB!.query(
        'persons',
        where: 'name = ?',
        whereArgs: [person.name],
      );
      if (existingMaps.isNotEmpty) {
        if (mounted) {
          UiHelper.showToast(context, 'Person Name Already Exists', type: 3);
        }
        return;
      }

      await Person.insert(currentDB!, person);
      if (mounted) {
        UiHelper.showToast(context, 'Added ${person.name}', type: 1);
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        UiHelper.showToast(context, 'Failed to add person', type: 3);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isPhone;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          insertPerson();
          widget.callback();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 16 : 20,
          vertical: isPhone ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Personal Information",
                    style: MyFont.bold(isPhone ? 18 : 20, color: MyColors.darkBlue),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: MyColors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: isPhone ? 150 : 160,
                width: isPhone ? 150 : 160,
                child: UploadCircle(
                  onFileSelected: (file) {
                    image = file;
                  },
                ),
              ),
              const SizedBox(height: 16),
              UiHelper.myTextField(
                label: "Name",
                hint: 'Enter full name',
                borderRadius: 12,
                controller: nameController,
                fontSize: isPhone ? 13 : 15,
              ),
              const SizedBox(height: 10),
              UiHelper.myTextField(
                label: "Phone",
                hint: '+92 000 000 0000',
                borderRadius: 12,
                controller: phoneController,
                fontSize: isPhone ? 13 : 15,
                textType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
                  LengthLimitingTextInputFormatter(15),
                ],
              ),
              const SizedBox(height: 10),
              UiHelper.myTextField(
                label: "Email",
                hint: 'example@email.com',
                borderRadius: 12,
                controller: emailController,
                fontSize: isPhone ? 13 : 15,
                textType: TextInputType.emailAddress,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9@._\-+]'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 75,
                child: UiHelper.myTextArea(
                  label: "Address",
                  hint: 'City, Country',
                  fontSize: isPhone ? 13 : 15,
                  controller: addressController,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => major = !major),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MyColors.lightGrey),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: Checkbox(
                                value: major,
                                onChanged: (val) => setState(() => major = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("Major Client", style: MyFont.medium(12, color: MyColors.textMain)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => isCustomer = !isCustomer),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCustomer ? MyColors.success.withValues(alpha: 0.1) : MyColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isCustomer ? MyColors.success : MyColors.primary),
                        ),
                        child: Center(
                          child: Text(
                            isCustomer ? "Customer" : "Supplier",
                            style: MyFont.bold(12, color: isCustomer ? MyColors.success : MyColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: UiHelper.myButton(
                        title: 'Close',
                        callback: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: UiHelper.myButton(
                        title: 'Save',
                        filled: true,
                        callback: () async {
                          insertPerson();
                          widget.callback();
                        },
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
}
