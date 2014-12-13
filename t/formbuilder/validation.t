#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use HTML::FormBuilder::Validation;
use HTML::FormBuilder::Select;

my $form_obj = create_form_object();

set_valid_input(\$form_obj);
is($form_obj->validate(),      1, '[validate=1]');
is($form_obj->get_has_error(), 0, '[get_has_error=0]');

is($form_obj->get_field_value('amount'),           123,   'amount=123');
is($form_obj->get_field_value('select_text_curr'), 'USD', 'select_text_curr=USD');
is($form_obj->get_field_value('w'),                'CR',  'w=CR');                   # test hidden value

set_valid_input(\$form_obj);
$form_obj->set_field_value('amount', 5);
is($form_obj->validate(),                        0,            'validate=0');
is($form_obj->get_has_error(),                   1,            'get_has_error=1');
is($form_obj->get_field_error_message('amount'), 'Too little', 'error message=Too little');

set_valid_input(\$form_obj);
$form_obj->set_field_value('amount', 501);
is($form_obj->validate(),                        0,          'validate=0');
is($form_obj->get_field_error_message('amount'), 'Too much', 'error message=Too much');

set_valid_input(\$form_obj);
$form_obj->set_field_value('amount', 'abc');
is($form_obj->validate(), 0, 'validate=0');
is($form_obj->get_field_error_message('amount'), 'Must be digit', 'error message=Must be digit');

set_valid_input(\$form_obj);
$form_obj->set_field_value('select_text_curr', '');
is($form_obj->validate(), 0, 'validate=0');
is($form_obj->get_field_error_message('select_text_curr'), 'Must be select', 'error message=Must be select');

set_valid_input(\$form_obj);
$form_obj->set_field_value('select_text_curr',   'USD');
$form_obj->set_field_value('select_text_amount', 'abc');
is($form_obj->validate(), 0, 'validate=0');
is($form_obj->get_field_error_message('select_text_amount'), 'Must be digits', 'error message=Must be digits');

set_valid_input(\$form_obj);
$form_obj->set_field_value('select_text_amount', '5');
is($form_obj->validate(),                                    0,            'validate=0');
is($form_obj->get_field_error_message('select_text_amount'), 'Too little', 'error message=Too little');

# Test on set_input_fields
my $input = {
    'name'               => 'Eric',
    'amount'             => '123',
    'select_text_curr'   => 'EUR',
    'select_text_amount' => '888',
    'submit'             => 'Submit',
    'test'               => '1',
};

$form_obj->set_input_fields($input);
is($form_obj->get_field_value('name'),               'Eric', 'name = Eric');
is($form_obj->get_field_value('amount'),             '123',  'amount = 123');
is($form_obj->get_field_value('select_text_curr'),   'EUR',  'select_text_curr = EUR');
is($form_obj->get_field_value('select_text_amount'), '888',  'select_text_amount = 888');
is($form_obj->get_field_value('test'),               undef,  'test = undef [not in form])');

sub set_valid_input {
    my $arg_ref = shift;

    ${$arg_ref}->set_field_value('name',               'Omid');
    ${$arg_ref}->set_field_value('amount',             '123');
    ${$arg_ref}->set_field_value('select_text_curr',   'USD');
    ${$arg_ref}->set_field_value('select_text_amount', '50');
}

sub check_existance_on_builded_html {
    my $arg_ref = shift;

    my $form_object = $arg_ref->{'form_obj'};
    my $reg_exp     = $arg_ref->{'reg_exp'};

    return $form_object->build() =~ /$reg_exp/;

}

sub create_form_object {
    my $form_obj;

    # Form attributes require to create new form object
    my $form_attributes = {
        'name'   => 'name_test_form',
        'id'     => 'id_test_form',
        'method' => 'post',
        'action' => 'http://localhost/some/where/test.cgi',
        'class'  => 'formObject',
    };

    # Create new form object
    lives_ok { $form_obj = new HTML::FormBuilder::Validation($form_attributes); } 'Create Form Validation';

    # Test object type
    isa_ok($form_obj, 'HTML::FormBuilder::Validation');

    my $fieldset_index = $form_obj->add_fieldset({});

    my $input_field_name = {
        'label' => {
            'text'     => 'Name',
            'for'      => 'name',
            'optional' => '0',
        },
        'input' => {
            'type'      => 'text',
            'id'        => 'name',
            'name'      => 'name',
            'maxlength' => 40,
            'value'     => '',
        },
        'error' => {
            'text'  => '',
            'id'    => 'error_name',
            'class' => 'errorfield',
        },
        'validation' => [{
                'type'             => 'regexp',
                'regexp'           => '[a-z]+',
                'case_insensitive' => 1,
                'err_msg'          => 'Not empty',
            },
        ],
    };

    my $input_field_amount = {
        'label' => {
            'text'     => 'Amount',
            'for'      => 'amount',
            'optional' => '0',
        },
        'input' => {
            'type'      => 'text',
            'id'        => 'amount',
            'name'      => 'amount',
            'maxlength' => 40,
            'value'     => '',
        },
        'error' => {
            'text'  => '',
            'id'    => 'error_amount',
            'class' => 'errorfield',
        },
        'validation' => [{
                'type'    => 'regexp',
                'regexp'  => '\w+',
                'err_msg' => 'Not empty',
            },
            {
                'type'    => 'regexp',
                'regexp'  => '\d+',
                'err_msg' => 'Must be digit',
            },
            {
                'type'    => 'min_amount',
                'amount'  => 50,
                'err_msg' => 'Too little',
            },
            {
                'type'    => 'max_amount',
                'amount'  => 500,
                'err_msg' => 'Too much',
            },
            {
                'type'     => 'custom',
                'function' => 'custom_amount_validation()',
                'err_msg'  => 'It is not good',
            }
        ],
    };

    my $select_curr = HTML::FormBuilder::Select->new(
        'id'      => 'select_text_curr',
        'name'    => 'select_text_curr',
        'type'    => 'select',
        'options' => [{value => ''}, {value => 'USD'}, {value => 'EUR'}],
    );
    my $input_amount = {
        'id'    => 'select_text_amount',
        'name'  => 'select_text_amount',
        'type'  => 'text',
        'value' => ''
    };
    my $input_field_select_text = {
        'label' => {
            'text'     => 'select_text',
            'for'      => 'select_text',
            'optional' => '0',
        },
        'input' => [$select_curr, $input_amount],
        'error' => {
            'text'  => '',
            'id'    => 'error_select_text',
            'class' => 'errorfield',
        },
        'validation' => [{
                'type'    => 'regexp',
                'id'      => 'select_text_curr',
                'regexp'  => '\w+',
                'err_msg' => 'Must be select',
            },
            {
                'type'    => 'regexp',
                'id'      => 'select_text_amount',
                'regexp'  => '\d+',
                'err_msg' => 'Must be digits',
            },
            {
                'type'    => 'min_amount',
                'id'      => 'select_text_amount',
                'amount'  => 50,
                'err_msg' => 'Too little',
            },
        ],
    };

    $form_obj->add_field(
        $fieldset_index,
        {
            'error' => {
                'id'    => 'error_general',
                'class' => 'errorfield',
            },
        });

    # Hidden fields
    my $input_hidden_field_broker = {
        'id'    => 'w',
        'name'  => 'w',
        'type'  => 'hidden',
        'value' => 'CR'
    };

    my $hidden_fields = {'input' => [$input_hidden_field_broker,]};
    $form_obj->add_field($fieldset_index, $hidden_fields);
    $form_obj->add_field($fieldset_index, $input_field_name);
    $form_obj->add_field($fieldset_index, $input_field_amount);
    $form_obj->add_field($fieldset_index, $input_field_select_text);

    return $form_obj;
}

done_testing;