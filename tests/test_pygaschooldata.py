"""
Tests for pygaschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pygaschooldata
    assert pygaschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pygaschooldata
    assert hasattr(pygaschooldata, 'fetch_enr')
    assert callable(pygaschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pygaschooldata
    assert hasattr(pygaschooldata, 'get_available_years')
    assert callable(pygaschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pygaschooldata
    assert hasattr(pygaschooldata, '__version__')
    assert isinstance(pygaschooldata.__version__, str)
