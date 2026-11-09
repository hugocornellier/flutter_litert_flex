#!/usr/bin/env python3
"""
Generates example/assets/flex_matrix_inverse.tflite

A one-op model, y = inverse(x) for a [2, 2] float32 matrix. TFLite has no
builtin matrix inverse, so with SELECT_TF_OPS the converter keeps the op as
the custom op FlexMatrixInverse, which only the Flex delegate can run. The
example's integration test runs it and checks the result, so it proves that
a real Flex kernel executes, not only that the library loads.

Requirements:
    pip install tensorflow==2.21.0

Usage (from the repository root):
    python scripts/generate_flex_test_model.py

Model:
    - one input x [2, 2] float32 and one output y [2, 2] float32
"""

import os

import numpy as np
import tensorflow as tf

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..',
                   'example', 'assets', 'flex_matrix_inverse.tflite')


class MatrixInverse(tf.Module):
    @tf.function(input_signature=[tf.TensorSpec([2, 2], tf.float32, name='x')])
    def invert(self, x):
        return {'y': tf.linalg.inv(x)}


def main():
    module = MatrixInverse()
    converter = tf.lite.TFLiteConverter.from_concrete_functions(
        [module.invert.get_concrete_function()], module)
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]
    model = converter.convert()

    # The model must hold the Flex op, or the test would not exercise flex.
    assert b'FlexMatrixInverse' in model, 'converter did not emit a Flex op'

    # The pip TensorFlow 2.21 interpreter does not link flex (it fails with
    # "Select TensorFlow op(s) ... not supported"), so check the expected
    # values with TensorFlow itself. The integration test runs the .tflite.
    x = np.array([[4.0, 7.0], [2.0, 6.0]], dtype=np.float32)
    y = module.invert(tf.constant(x))['y'].numpy()
    np.testing.assert_allclose(y, [[0.6, -0.7], [-0.2, 0.4]], atol=1e-6)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'wb') as f:
        f.write(model)
    print(f'Wrote {os.path.normpath(OUT)} ({len(model)} bytes), '
          f'TensorFlow {tf.__version__}')
    print(y)


if __name__ == '__main__':
    main()
