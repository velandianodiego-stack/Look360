import 'package:material_ui/material_ui.dart';

import '../../models/product_model.dart';
import '../../services/supabase_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<ProductModel> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await SupabaseService.instance.getProductos();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los productos: $error')),
      );
    }
  }

  Future<void> _addProduct() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que deseas eliminar ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await SupabaseService.instance.eliminarProducto(product.id);
      if (mounted) _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el producto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add),
        label: const Text('Añadir producto'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _products.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('No hay productos')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: SizedBox(
                              width: 58,
                              height: 58,
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stackTrace) =>
                                    const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 32,
                                    ),
                              ),
                            ),
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.category} · ${product.price.toStringAsFixed(2)} · Stock: ${product.stock}\nTallas: ${product.sizes.join(', ')}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Eliminar producto',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteProduct(product),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _sizesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _urlCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _sizesCtrl.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;

  String? _urlValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final uri = Uri.tryParse(value!.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Introduce una URL válida';
    }
    return null;
  }

  String? _positiveNumber(String? value, {required bool integer}) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final number = integer
        ? int.tryParse(value!.trim())
        : double.tryParse(value!.trim());
    if (number == null || number < 0) return 'Introduce un número válido';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final sizes = _sizesCtrl.text
        .split(',')
        .map((size) => size.trim())
        .where((size) => size.isNotEmpty)
        .toList();
    if (sizes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Añade al menos una talla')));
      return;
    }

    setState(() => _saving = true);
    try {
      await SupabaseService.instance.crearProducto(
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        imageUrl: _urlCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        sizes: sizes,
        stock: int.parse(_stockCtrl.text.trim()),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear el producto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir producto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción *'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL de imagen *'),
              validator: _urlValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'Categoría *'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Precio *'),
                    validator: (value) =>
                        _positiveNumber(value, integer: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock *'),
                    validator: (value) => _positiveNumber(value, integer: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sizesCtrl,
              decoration: const InputDecoration(
                labelText: 'Tallas *',
                hintText: 'Ejemplo: S, M, L',
              ),
              validator: _required,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando...' : 'Guardar producto'),
            ),
          ],
        ),
      ),
    );
  }
}
