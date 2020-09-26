import tfcoreml as tf_converter

tf_converter.convert(
    tf_model_path = 'image_classification.h5.pb',
    mlmodel_path = 'image_classification.mlmodel',
    input_name_shape_dict = {"flatten_input:0":[1,28,28,1]},
    image_input_names = ['flatten_input:0'],
    output_feature_names = ['output_node0:0'],
    class_labels = 'labels.txt')
