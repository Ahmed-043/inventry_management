import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/person.dart';
import 'package:inventry_management/Home_Page/Orders_panel/New_Order_Page/dialogs/choose_person.dart';
import 'package:inventry_management/Shared_Widgets/date_time.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import 'add_expense_logic.dart';

class AddExpenseDialog extends StatefulWidget {
  final VoidCallback? onSave;
  const AddExpenseDialog({super.key, this.onSave});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  late AddExpenseController controller;
  @override
 initState()  {
    super.initState();
    controller = AddExpenseController();
    controller.loadCategories();
    controller.addListener(() async {
      if (mounted) {
        setState(() {
      });
      }
    });
  }


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainSection(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      )
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text('Add Entry', style: MyFont.bold(24, color: MyColors.dark)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade600),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        // Left Column
        SizedBox(
          width: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  _typeButton('Expense', !controller.isIncome, MyColors.error),
                  const SizedBox(width: 12),
                  _typeButton('Income', controller.isIncome, MyColors.success),
                ],
              ),
              const SizedBox(height: 24),
              UiHelper.myTextField(
                label: 'Title',
                controller: controller.title,
                hint: 'Enter title (e.g. Office Rent)',
                fontSize: 15,
              ),
              const SizedBox(height: 24),
              UiHelper.myTextField(
                label: 'Amount',
                controller: controller.amount,
                hint: '0.00',
                prefixText: 'Rs. ',
                fontSize: 15,
                textType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
              const SizedBox(height: 24),
              UiHelper.myTextArea(
                label: 'Remark',
                controller: controller.remark,
                hint: 'Additional notes...',
                maxLines: 3,
                fontSize: 15,
              ),
              const SizedBox(height: 24),
              _buildTransactionCheckbox(),
            ],
          ),
        ),
        // Right Column
        SizedBox(
          width: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),
              _buildPersonPicker(),
              const SizedBox(height: 24),
              _buildPaymentMethodPicker(),

            ],
          ),
        ),
      ],
    );
  }

  Widget _typeButton(String label, bool isSelected, Color color) {
    return Expanded(
      child: ScaledContainer(
        child: InkWell(
          onTap: () => controller.updateType(label == 'Income'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                label,
                style: MyFont.bold(14, color: isSelected ? Colors.white : color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expense Date', style: MyFont.semiBold(14, color: MyColors.darkBlue.withOpacity(0.8))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            DateTime? picked = await pickDate(context, DateTime.fromMillisecondsSinceEpoch(controller.expenseDate));
            if (picked != null) {
              controller.updateDate(picked.millisecondsSinceEpoch);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(width: 2, color: MyColors.lightGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: MyColors.darkBlue),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(controller.expenseDate)),
                  style: MyFont.normal(15, color: MyColors.darkBlue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Person (Optional)', style: MyFont.semiBold(14, color: MyColors.darkBlue.withOpacity(0.8))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final person = await UiHelper.pushPage<Person?>(
              context: context,
              opaque: false,
              barrierDismissible: true,
              page: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 400,
                    height: 600,
                    decoration: UiHelper.myDecoration(),
                    child: const ChoosePerson(filter: 0),
                  ),
                ),
              ),
            );
            if (person != null) {
              controller.updatePerson(person);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(width: 2, color: MyColors.lightGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 20, color: MyColors.darkBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.selectedPerson?.name ?? 'Select Person',
                    style: MyFont.normal(15, color: controller.selectedPerson == null ? MyColors.grey : MyColors.darkBlue),
                  ),
                ),
                if (controller.selectedPerson != null)
                  IconButton(
                    onPressed: () => controller.updatePerson(null),
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodPicker() {
    final methods = ['Cash', 'Digital', 'Bank', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: MyFont.semiBold(14, color: MyColors.darkBlue.withOpacity(0.8))),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 2, color: MyColors.lightGrey),
          ),
          child: DropdownButtonHideUnderline(
            
            child: DropdownButton<String>(
              borderRadius: .circular(10),
              dropdownColor: MyColors.translucent,
              value: controller.paymentMethod,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: MyFont.normal(15)))).toList(),
              onChanged: (val) => controller.updatePaymentMethod(val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCheckbox() {
    return InkWell(
      onTap: () => controller.updateRecordAsTransaction(!controller.recordAsTransaction),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: controller.recordAsTransaction,
                onChanged: (val) => controller.updateRecordAsTransaction(val!),
                activeColor: MyColors.darkBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Record as transaction also',
              style: MyFont.semiBold(14, color: MyColors.darkBlue.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style:  MyFont.semiBold(14, color: MyColors.darkBlue.withOpacity(0.8))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownMenuTheme(
                data: DropdownMenuThemeData(
                  menuStyle: MenuStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    elevation: WidgetStateProperty.all(6),
                  ),
                ),
                child: DropdownMenu<int>(
                  controller: controller.categoryController,
                  hintText: 'Select or type category',
                  expandedInsets: EdgeInsets.zero,
                  inputDecorationTheme: InputDecorationTheme(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(width: 2, color: MyColors.lightGrey),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(width: 2, color: MyColors.darkBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(width: 2, color: MyColors.darkBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  textStyle: MyFont.semiBold(14, color: MyColors.dark),
                  onSelected: (int? value) => controller.selectCategory(value),
                  dropdownMenuEntries: controller.categories.map((c) {
                    return DropdownMenuEntry<int>(value: c.id!, label: c.name);
                  }).toList(),
                ),
              ),
            ),
            if (controller.showAddCategoryIcon)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Material(
                  color: MyColors.success.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final name = controller.categoryController.text.trim();
                      if (name.isNotEmpty) {
                        final res = await controller.addNewCategory(name);
                        if (res != null && mounted) {
                          UiHelper.showToast(context, res, type: 1);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.add, color: MyColors.success, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: MyColors.translucent.withAlpha(30),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: MyColors.lightGrey, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 140,
            height: 50,
            child: UiHelper.myButton(
              title: 'Cancel',
              callback: () => Navigator.pop(context),
              textSize: 15,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            height: 50,
            child: UiHelper.myButton(
              title: controller.isLoading ? null : 'Save Entry',
              filled: true,
              textSize: 15,
              child: controller.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : null,
              callback: controller.isLoading ? () {} : _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final error = await controller.saveExpense();
    if (!mounted) return;

    if (error != null) {
      UiHelper.showToast(context, error, type: 3);
    } else {
      widget.onSave?.call();
      Navigator.pop(context);
    }
  }
}
